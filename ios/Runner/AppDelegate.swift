import BackgroundTasks
import Flutter
import UIKit
import UserNotifications

enum CatBackgroundConfig {
  static let channelName = "com.today.meowly/background"
}

struct CatPayload: Codable {
  let id: String
  let url: String
  let createdAt: String
  let cachedPath: String
}

enum CatBackgroundError: Error {
  case invalidResponse
  case downloadFailed
}

@available(iOS 13.0, *)
final class CatBackgroundManager {
  static let shared = CatBackgroundManager()

  private let taskIdentifier = "com.today.meowly.catRefresh"
  private let refreshIntervalKey = "cat_background_refresh_interval"
  private let defaults = UserDefaults.standard
  private let notificationCenter = UNUserNotificationCenter.current()
  private let worker = CatBackgroundWorker()
#if targetEnvironment(simulator)
  private var simulatorTimer: DispatchSourceTimer?
#endif

  private init() {}

  func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handle(task: refreshTask)
    }
  }

  func configure(intervalMinutes: Int, enableNotifications: Bool) {
    print("[BGTask] configure interval=\(intervalMinutes) enableNotifications=\(enableNotifications)")
    defaults.set(intervalMinutes, forKey: refreshIntervalKey)
    if enableNotifications {
      notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    updateBackgroundFetchInterval(minutes: intervalMinutes)
    scheduleNext()
  }

  func schedule(intervalMinutes: Int) {
    print("[BGTask] schedule interval=\(intervalMinutes)")
    defaults.set(intervalMinutes, forKey: refreshIntervalKey)
    updateBackgroundFetchInterval(minutes: intervalMinutes)
    scheduleNext()
  }

  func cancel() {
    print("[BGTask] cancel")
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
#if targetEnvironment(simulator)
    simulatorTimer?.cancel()
    simulatorTimer = nil
#endif
  }

  func triggerNow(completion: @escaping (Bool) -> Void) {
    Task {
      print("[BGTask] triggerNow start")
      let result = await executeRefresh()
      scheduleNext()
      print("[BGTask] triggerNow result=\(result)")
      completion(result)
    }
  }

  private func handle(task: BGAppRefreshTask) {
    print("[BGTask] handle task \(task.identifier)")
    scheduleNext()
    task.expirationHandler = { [weak task] in
      print("[BGTask] task expired")
      task?.setTaskCompleted(success: false)
    }

    Task {
      print("[BGTask] executeRefresh from BGTask start")
      let success = await executeRefresh()
      print("[BGTask] executeRefresh from BGTask finished success=\(success)")
      task.setTaskCompleted(success: success)
    }
  }

  func scheduleNext() {
    let intervalMinutes = defaults.integer(forKey: refreshIntervalKey)
    let interval = max(intervalMinutes, 1)
    print("[BGTask] scheduleNext intervalMinutes=\(intervalMinutes) intervalUsed=\(interval)")

#if targetEnvironment(simulator)
    simulatorTimer?.cancel()
    simulatorTimer = nil

    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now() + .seconds(interval * 60))
    timer.setEventHandler { [weak self] in
      guard let self = self else { return }
      print("[BGTask] simulator timer fired")
      Task {
        let success = await self.executeRefresh()
        print("[BGTask] simulator timer finished success=\(success)")
        self.scheduleNext()
      }
    }
    simulatorTimer = timer
    timer.resume()
    print("[BGTask] simulator timer scheduled in \(interval) minutes")
    return
#endif

    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)

    let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(interval * 60))

    DispatchQueue.main.async {
      do {
        try BGTaskScheduler.shared.submit(request)
      } catch {
#if DEBUG
        print("Failed to schedule background task: \(error)")
#endif
      }
      BGTaskScheduler.shared.getPendingTaskRequests { requests in
        let ids = requests.map { $0.identifier }
        print("[BGTask] pending tasks:", ids)
      }
    }
  }

  private func updateBackgroundFetchInterval(minutes: Int) {
    let intervalSeconds = TimeInterval(max(minutes, 1) * 60)
    DispatchQueue.main.async {
      print("[BGTask] updateBackgroundFetchInterval seconds=\(intervalSeconds)")
      UIApplication.shared.setMinimumBackgroundFetchInterval(intervalSeconds)
    }
  }

  private func executeRefresh() async -> Bool {
    print("[BGTask] executeRefresh() start")
    var success = false
    do {
      guard let payload = try await worker.perform() else {
        print("[BGTask] executeRefresh() no refresh needed")
        success = false
        return false
      }
      await showNotification()
      success = true
      return true
    } catch {
#if DEBUG
      print("Cat background refresh failed: \(error)")
#endif
      success = false
      return false
    }
  }

  func performBackgroundFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("[BGTask] performFetch begin")
    Task {
      let didRefresh = await executeRefresh()
      scheduleNext()
      print("[BGTask] performFetch finished didRefresh=\(didRefresh)")
      completionHandler(didRefresh ? .newData : .noData)
    }
  }

  @MainActor
  private func showNotification() {
    let content = UNMutableNotificationContent()
    content.title = NSLocalizedString("New cat is ready!", comment: "Background notification title")
    content.body = NSLocalizedString("Open the app to see the latest cat picture.", comment: "Background notification body")
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: "cat_refresh_notification",
      content: content,
      trigger: nil
    )
    notificationCenter.add(request, withCompletionHandler: nil)
  }
}

@available(iOS 13.0, *)
final class CatBackgroundWorker {
  private let cacheKey = "flutter.cat_cache"
  private let historyKey = "flutter.cat_history"
  private let maxHistory = 30
  private let defaults = UserDefaults.standard
  private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  func perform() async throws -> CatPayload? {
    if !shouldRefresh() {
      return nil
    }

    let metadata = try await fetchCatJson()
    guard let url = resolveUrl(from: metadata) else {
      throw CatBackgroundError.invalidResponse
    }
    let fileUrl = try await downloadImage(from: url)
    let payload = CatPayload(
      id: metadata["id"] as? String ?? metadata["_id"] as? String ?? "",
      url: url.absoluteString,
      createdAt: isoFormatter.string(from: Date()),
      cachedPath: fileUrl.path
    )
    try saveCache(payload: payload)
    try appendHistory(with: payload)
    return payload
  }

  private func shouldRefresh() -> Bool {
    guard let raw = defaults.string(forKey: cacheKey),
          let data = raw.data(using: .utf8),
          let cached = try? JSONDecoder().decode(CatPayload.self, from: data),
          let createdAt = isoFormatter.date(from: cached.createdAt) else {
      return true
    }

    let intervalMinutes = defaults.integer(forKey: "cat_background_refresh_interval")
    let interval = max(intervalMinutes, 1)
    let elapsed = Date().timeIntervalSince(createdAt)
    return elapsed >= TimeInterval(interval * 60)
  }

  private func fetchCatJson() async throws -> [String: Any] {
    guard let url = URL(string: "https://cataas.com/cat?json=true&position=center") else {
      throw CatBackgroundError.invalidResponse
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw CatBackgroundError.invalidResponse
    }

    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    guard let json = jsonObject as? [String: Any] else {
      throw CatBackgroundError.invalidResponse
    }
    return json
  }

  private func resolveUrl(from json: [String: Any]) -> URL? {
    guard let urlValue = json["url"] as? String else {
      return nil
    }
    if urlValue.hasPrefix("http") {
      return URL(string: urlValue)
    }
    return URL(string: "https://cataas.com\(urlValue)")
  }

  private func downloadImage(from url: URL) async throws -> URL {
    let tempUrl: URL
    let response: URLResponse

    if #available(iOS 15.0, *) {
      let result = try await URLSession.shared.download(from: url)
      tempUrl = result.0
      response = result.1
    } else {
      let legacyResult = try await legacyDownload(from: url)
      tempUrl = legacyResult.0
      response = legacyResult.1
    }

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw CatBackgroundError.downloadFailed
    }

    let directory = try FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("cats", isDirectory: true)

    if !FileManager.default.fileExists(atPath: directory.path) {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    let fileExtension = resolveExtension(from: url)
    let fileName = "cat_\(Int(Date().timeIntervalSince1970 * 1000)).\(fileExtension)"
    let destination = directory.appendingPathComponent(fileName)

    try? FileManager.default.removeItem(at: destination)
    try FileManager.default.moveItem(at: tempUrl, to: destination)
    return destination
  }

  private func resolveExtension(from url: URL) -> String {
    let ext = url.pathExtension.lowercased()
    guard !ext.isEmpty, ext.count <= 5 else {
      return "jpg"
    }
    return ext
  }

  private func legacyDownload(from url: URL) async throws -> (URL, URLResponse) {
    try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        guard let tempUrl = tempUrl, let response = response else {
          continuation.resume(throwing: CatBackgroundError.downloadFailed)
          return
        }
        continuation.resume(returning: (tempUrl, response))
      }
      task.resume()
    }
  }

  private func saveCache(payload: CatPayload) throws {
    let data = try JSONEncoder().encode(payload)
    if let jsonString = String(data: data, encoding: .utf8) {
      defaults.set(jsonString, forKey: cacheKey)
    }
  }

  private func appendHistory(with payload: CatPayload) throws {
    var history = loadHistory()

    history.removeAll { $0.cachedPath == payload.cachedPath }
    history.insert(payload, at: 0)

    if history.count > maxHistory {
      let removed = history.suffix(from: maxHistory)
      removed.forEach { deleteFile(atPath: $0.cachedPath) }
      history = Array(history.prefix(maxHistory))
    }

    if history.isEmpty {
      defaults.removeObject(forKey: historyKey)
    } else {
      let data = try JSONEncoder().encode(history)
      if let jsonString = String(data: data, encoding: .utf8) {
        defaults.set(jsonString, forKey: historyKey)
      }
    }
  }

  private func loadHistory() -> [CatPayload] {
    guard let raw = defaults.string(forKey: historyKey),
          let data = raw.data(using: .utf8),
          let history = try? JSONDecoder().decode([CatPayload].self, from: data) else {
      return []
    }
    return history
  }

  private func deleteFile(atPath path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 13.0, *) {
      CatBackgroundManager.shared.registerBackgroundTasks()
    }
    UNUserNotificationCenter.current().delegate = self

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: CatBackgroundConfig.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handle(call: call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "initialize":
      let interval = arguments?["refreshIntervalMinutes"] as? Int ?? 5
      let notifications = arguments?["enableNotifications"] as? Bool ?? true
      if #available(iOS 13.0, *) {
        CatBackgroundManager.shared.configure(intervalMinutes: interval, enableNotifications: notifications)
      }
      result(nil)
    case "schedule":
      let interval = arguments?["refreshIntervalMinutes"] as? Int ?? 5
      if #available(iOS 13.0, *) {
        CatBackgroundManager.shared.schedule(intervalMinutes: interval)
      }
      result(nil)
    case "cancel":
      if #available(iOS 13.0, *) {
        CatBackgroundManager.shared.cancel()
      }
      result(nil)
    case "triggerNow":
      guard #available(iOS 13.0, *) else {
        result(false)
        return
      }
      CatBackgroundManager.shared.triggerNow { success in
        DispatchQueue.main.async {
          result(success)
        }
      }
    case "setDebugLogging":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .sound])
  }

  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    guard #available(iOS 13.0, *) else {
      completionHandler(.noData)
      return
    }
    CatBackgroundManager.shared.performBackgroundFetch(completionHandler: completionHandler)
  }

  override func application(
    _ application: UIApplication,
    shouldSaveSecureApplicationState coder: NSCoder
  ) -> Bool {
    false
  }

  override func application(
    _ application: UIApplication,
    shouldRestoreSecureApplicationState coder: NSCoder
  ) -> Bool {
    false
  }
}
