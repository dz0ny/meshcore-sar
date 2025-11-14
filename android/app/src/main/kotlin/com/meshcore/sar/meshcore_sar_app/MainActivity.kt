package com.meshcore.sar.meshcore_sar_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register BuildInfoChannel to expose build information to Flutter
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BuildInfoChannel.CHANNEL_NAME
        ).setMethodCallHandler(BuildInfoChannel())
    }
}
