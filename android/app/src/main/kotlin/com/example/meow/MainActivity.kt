package com.today.meowly

import android.os.Bundle
import com.today.meowly.background.CatBackgroundBridge
import com.today.meowly.background.CatBackgroundConfig
import com.today.meowly.background.CatBackgroundScheduler
import com.today.meowly.background.CatNotificationHelper
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
