package com.example.meow

import android.os.Bundle
import com.example.meow.background.CatBackgroundBridge
import com.example.meow.background.CatBackgroundConfig
import com.example.meow.background.CatBackgroundScheduler
import com.example.meow.background.CatNotificationHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CatBackgroundConfig.CHANNEL_NAME,
        )

        val bridge = CatBackgroundBridge(
            context = this,
            notificationHelper = CatNotificationHelper(this),
            scheduler = CatBackgroundScheduler(this),
        )

        channel.setMethodCallHandler(bridge)
    }
}
