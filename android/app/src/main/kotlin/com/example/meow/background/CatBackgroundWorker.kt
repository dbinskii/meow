package com.example.meow.background

import android.content.Context
import android.net.Uri
import android.util.Log
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.util.Date
import java.util.Locale

class CatBackgroundWorker(private val context: Context) {

    private val appPrefs =
        context.getSharedPreferences(FLUTTER_SHARED_PREFS, Context.MODE_PRIVATE)
    private val loggerTag = "CatBackgroundWorker"

    var notificationTitle: String = ""
        private set
    var notificationBody: String = ""
        private set

    fun perform(): Boolean {
        return try {
            if (!shouldRefresh()) {
                return false
            }
            val catJson = fetchCatJson() ?: return false
            val resolvedUrl = resolveCatUrl(catJson)
            val cachedFile = downloadImage(resolvedUrl) ?: return false
            val createdAtIso = isoTimestamp()
            val catPayload = JSONObject().apply {
                put("id", catJson.optString("id", catJson.optString("_id", "")))
                put("url", resolvedUrl)
                put("createdAt", createdAtIso)
                put("cachedPath", cachedFile.absolutePath)
            }

            saveCache(catPayload)
            appendHistory(catPayload)

            notificationTitle = context.getString(
                com.example.meow.R.string.cat_notification_title,
            )
            notificationBody = context.getString(
                com.example.meow.R.string.cat_notification_body,
            )
            true
        } catch (error: Exception) {
            Log.e(loggerTag, "Failed to refresh cat", error)
            false
        }
    }

    private fun shouldRefresh(): Boolean {
        val cachedRaw = appPrefs.getString(CACHE_KEY, null) ?: return true
        return try {
            val cached = JSONObject(cachedRaw)
            val createdAt = cached.optString("createdAt", null) ?: return true
            val parsed = parseTimestamp(createdAt) ?: return true
            val diffMillis = Date().time - parsed.time
            val intervalMillis =
                CatBackgroundConfig.readIntervalMinutes(context) * 60_000L
            diffMillis >= intervalMillis
        } catch (_: JSONException) {
            true
        }
    }

    private fun fetchCatJson(): JSONObject? {
        val endpoint = URL("https://cataas.com/cat?json=true&position=center")
        val connection = endpoint.openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.setRequestProperty("Accept", "application/json")
        connection.connectTimeout = 20_000
        connection.readTimeout = 20_000

        return try {
            val status = connection.responseCode
            if (status != HttpURLConnection.HTTP_OK) {
                Log.w(loggerTag, "Unexpected status code $status when fetching cat")
                null
            } else {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = reader.use { it.readText() }
                JSONObject(response)
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun resolveCatUrl(json: JSONObject): String {
        val base = json.optString("url")
        return if (base.startsWith("http")) {
            base
        } else {
            "https://cataas.com$base"
        }
    }

    private fun downloadImage(urlString: String): File? {
        val uri = Uri.parse(urlString)
        val connection = URL(urlString).openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 20_000
        connection.readTimeout = 20_000

        return try {
            val status = connection.responseCode
            if (status != HttpURLConnection.HTTP_OK) {
                Log.w(loggerTag, "Failed to download image status=$status")
                null
            } else {
                val directory = File(context.filesDir, "cats")
                if (!directory.exists()) directory.mkdirs()

                val extension = resolveExtension(uri.lastPathSegment)
                val timestamp = System.currentTimeMillis()
                val file = File(directory, "cat_$timestamp.$extension")

                BufferedInputStream(connection.inputStream).use { input ->
                    FileOutputStream(file).use { output ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        while (true) {
                            val read = input.read(buffer)
                            if (read == -1) break
                            output.write(buffer, 0, read)
                        }
                        output.flush()
                    }
                }
                file
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun resolveExtension(segment: String?): String {
        if (segment.isNullOrBlank()) return "jpg"
        val parts = segment.split('.')
        if (parts.size < 2) return "jpg"
        val ext = parts.last().lowercase(Locale.US)
        return if (ext.length in 1..5) ext else "jpg"
    }

    private fun saveCache(payload: JSONObject) {
        appPrefs.edit()
            .putString(CACHE_KEY, payload.toString())
            .apply()
    }

    private fun appendHistory(cat: JSONObject) {
        val historyRaw = appPrefs.getString(HISTORY_KEY, null)
        val history =
            if (historyRaw.isNullOrBlank()) JSONArray() else JSONArray(historyRaw)
        val filtered = JSONArray()
        val cachedPath = cat.optString("cachedPath", "")

        val seen = mutableSetOf<String>()
        if (cachedPath.isNotEmpty()) {
            seen.add(cachedPath)
        }

        filtered.put(cat)

        for (i in 0 until history.length()) {
            val entry = history.optJSONObject(i) ?: continue
            val path = entry.optString("cachedPath", "")
            if (path.isEmpty()) continue
            if (seen.contains(path)) continue
            seen.add(path)
            filtered.put(entry)
            if (filtered.length() >= MAX_HISTORY) break
        }

        deleteRemovedEntries(history, filtered)

        appPrefs.edit()
            .putString(HISTORY_KEY, filtered.toString())
            .apply()
    }

    private fun deleteRemovedEntries(oldHistory: JSONArray, newHistory: JSONArray) {
        val retained = mutableSetOf<String>()
        for (i in 0 until newHistory.length()) {
            val entry = newHistory.optJSONObject(i) ?: continue
            val path = entry.optString("cachedPath", "")
            if (path.isNotEmpty()) {
                retained.add(path)
            }
        }

        for (i in 0 until oldHistory.length()) {
            val entry = oldHistory.optJSONObject(i) ?: continue
            val path = entry.optString("cachedPath", "")
            if (path.isNotEmpty() && !retained.contains(path)) {
                val file = File(path)
                if (file.exists()) {
                    runCatching { file.delete() }
                }
            }
        }
    }

    private fun isoTimestamp(): String {
        return OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
    }

    private fun parseTimestamp(value: String): Date? {
        return try {
            val instant = try {
                OffsetDateTime.parse(value, DateTimeFormatter.ISO_OFFSET_DATE_TIME).toInstant()
            } catch (offsetError: DateTimeParseException) {
                val local = LocalDateTime.parse(value, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                local.atZone(ZoneId.systemDefault()).toInstant()
            }
            Date.from(instant)
        } catch (_: DateTimeParseException) {
            null
        }
    }

    companion object {
        private const val FLUTTER_SHARED_PREFS = "FlutterSharedPreferences"
        private const val CACHE_KEY = "flutter.cat_cache"
        private const val HISTORY_KEY = "flutter.cat_history"
        private const val MAX_HISTORY = 30
    }
}

