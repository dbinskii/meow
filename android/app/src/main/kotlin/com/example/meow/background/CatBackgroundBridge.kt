package com.today.meowly.background

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class CatBackgroundBridge(
    private val context: Context,
    private val notificationHelper: CatNotificationHelper,
    private val scheduler: CatBackgroundScheduler,
) : MethodChannel.MethodCallHandler {

    private val scope = CoroutineScope(Dispatchers.Default)
    private var debugLogging = false
    private val loggerTag = "CatBackgroundBridge"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val interval = call.argument<Int>("refreshIntervalMinutes")
                    ?: CatBackgroundConfig.DEFAULT_REFRESH_INTERVAL_MINUTES
                val notificationsEnabled = call.argument<Boolean>("enableNotifications") ?: true
                if (debugLogging) {
                    Log.d(
                        loggerTag,
                        "initialize: interval=$interval notifications=$notificationsEnabled",
                    )
                }
                CatBackgroundConfig.saveIntervalMinutes(context, interval)
                if (notificationsEnabled) {
                    notificationHelper.ensureChannel()
                    requestNotificationPermissionIfNeeded()
                }
                scheduler.scheduleNext(interval)
                requestExactAlarmPermissionIfNeeded()
                result.success(null)
            }

            "schedule" -> {
                val interval = call.argument<Int>("refreshIntervalMinutes")
                    ?: CatBackgroundConfig.readIntervalMinutes(context)
                if (debugLogging) {
                    Log.d(loggerTag, "schedule: interval=$interval")
                }
                CatBackgroundConfig.saveIntervalMinutes(context, interval)
                scheduler.scheduleNext(interval)
                requestExactAlarmPermissionIfNeeded()
                result.success(null)
            }

            "scheduleWithDelay" -> {
                val delay = call.argument<Int>("delayMinutes") ?: 0
                val resolvedDelay = delay.coerceAtLeast(1)
                if (debugLogging) {
                    Log.d(loggerTag, "scheduleWithDelay: delay=$resolvedDelay")
                }
                scheduler.scheduleNext(resolvedDelay)
                requestExactAlarmPermissionIfNeeded()
                result.success(null)
            }

            "cancel" -> {
                if (debugLogging) {
                    Log.d(loggerTag, "cancel")
                }
                scheduler.cancel()
                result.success(null)
            }

            "triggerNow" -> {
                if (debugLogging) {
                    Log.d(loggerTag, "triggerNow invoked")
                }
                scope.launch(Dispatchers.IO) {
                    val worker = CatBackgroundWorker(context)
                    val success = worker.perform()
                    if (success) {
                        notificationHelper.showNewCatNotification(
                            worker.notificationTitle,
                            worker.notificationBody,
                        )
                    }
                    scheduler.scheduleNext()
                    withContext(Dispatchers.Main) {
                        result.success(success)
                    }
                }
            }

            "setDebugLogging" -> {
                debugLogging = call.argument<Boolean>("enabled") ?: false
                if (debugLogging) {
                    Log.d(loggerTag, "debug logging enabled")
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val activity = context as? Activity ?: return
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATIONS_PERMISSION,
            )
        }
    }

    private fun requestExactAlarmPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        if (scheduler.canScheduleExactAlarms()) return
        val activity = context as? Activity ?: return
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
            data = Uri.parse("package:${activity.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivity(intent)
        }
    }

    companion object {
        private const val REQUEST_NOTIFICATIONS_PERMISSION = 1001
    }
}

