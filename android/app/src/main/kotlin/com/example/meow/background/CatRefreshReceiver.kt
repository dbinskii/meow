package com.example.meow.background

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class CatRefreshReceiver : BroadcastReceiver() {

    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            CatBackgroundScheduler(context).scheduleNext()
            return
        }
        val pendingResult = goAsync()
        coroutineScope.launch {
            val worker = CatBackgroundWorker(context)
            val result = withContext(Dispatchers.IO) {
                worker.perform()
            }
            if (result) {
                CatNotificationHelper(context).showNewCatNotification(
                    worker.notificationTitle,
                    worker.notificationBody,
                )
            }
            CatBackgroundScheduler(context).scheduleNext()
            pendingResult.finish()
        }
    }
}

