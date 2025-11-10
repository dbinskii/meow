package com.today.meowly.background

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import kotlin.math.max

class CatBackgroundScheduler(private val context: Context) {

    private val alarmManager: AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    fun scheduleNext(intervalMinutes: Int? = null) {
        val resolvedInterval = max(intervalMinutes ?: CatBackgroundConfig.readIntervalMinutes(context), 1)
        val triggerAtMillis = System.currentTimeMillis() + resolvedInterval * 60_000L
        val pendingIntent = buildPendingIntent()

        alarmManager?.cancel(pendingIntent)

        if (alarmManager == null) {
            return
        }

        val canScheduleExact = canScheduleExactAlarms()

        try {
            if (canScheduleExact) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent,
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent,
                    )
                }
            } else {
                Log.w(TAG, "Exact alarms not permitted; scheduling inexact alarm instead.")
                scheduleInexact(triggerAtMillis, pendingIntent)
            }
        } catch (securityException: SecurityException) {
            Log.w(
                TAG,
                "Exact alarm scheduling denied, falling back to inexact alarm.",
                securityException,
            )
            scheduleInexact(triggerAtMillis, pendingIntent)
        }
    }

    fun cancel() {
        alarmManager?.cancel(buildPendingIntent())
    }

    private fun buildPendingIntent(): PendingIntent {
        val intent = Intent(context, CatRefreshReceiver::class.java)
        val flags = PendingIntent.FLAG_CANCEL_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            flags,
        )
    }

    fun canScheduleExactAlarms(): Boolean {
        if (alarmManager == null) return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun scheduleInexact(triggerAtMillis: Long, pendingIntent: PendingIntent) {
        val alarm = alarmManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarm.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        } else {
            alarm.set(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        }
    }

    companion object {
        private const val TAG = "CatBackgroundScheduler"
        private const val REQUEST_CODE = 2010
    }
}