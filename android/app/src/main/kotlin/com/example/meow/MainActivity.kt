package com.today.meowly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import com.today.meowly.background.CatBackgroundBridge
import com.today.meowly.background.CatBackgroundConfig
import com.today.meowly.background.CatBackgroundScheduler
import com.today.meowly.background.CatNotificationHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {

    private lateinit var backgroundChannel: MethodChannel
    private var isReceiverRegistered = false

    private val catRefreshReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (!::backgroundChannel.isInitialized) {
                return
            }
            val createdAt =
                intent?.getStringExtra(CatBackgroundConfig.EXTRA_CREATED_AT)
            val payload =
                if (createdAt.isNullOrBlank()) emptyMap<String, Any>()
                else mapOf("createdAt" to createdAt)
            runCatching {
                backgroundChannel.invokeMethod("catRefreshed", payload)
            }.onFailure { error ->
                Log.w("MainActivity", "Failed to notify Flutter of refresh", error)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        backgroundChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CatBackgroundConfig.CHANNEL_NAME,
        )

        val bridge = CatBackgroundBridge(
            context = this,
            notificationHelper = CatNotificationHelper(this),
            scheduler = CatBackgroundScheduler(this),
        )

        backgroundChannel.setMethodCallHandler(bridge)
    }

    override fun onResume() {
        super.onResume()
        if (!isReceiverRegistered) {
            ContextCompat.registerReceiver(
                this,
                catRefreshReceiver,
                IntentFilter(CatBackgroundConfig.ACTION_CAT_REFRESHED),
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            isReceiverRegistered = true
        }
    }

    override fun onPause() {
        if (isReceiverRegistered) {
            runCatching { unregisterReceiver(catRefreshReceiver) }
            isReceiverRegistered = false
        }
        super.onPause()
    }
}
