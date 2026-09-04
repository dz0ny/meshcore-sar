package com.meshcore.sar.meshcore_sar_app

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Platform channel for exposing build information to Flutter
 * Provides access to BuildConfig values that are injected at build time
 */
class BuildInfoChannel : MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.meshcore.sar/build_info"
        const val METHOD_GET_COMMIT_HASH = "getCommitHash"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_GET_COMMIT_HASH -> {
                try {
                    // Get commit hash from BuildConfig
                    // This value is injected by gradle at build time
                    val commitHash = BuildConfig.COMMIT_HASH
                    result.success(commitHash)
                } catch (e: Exception) {
                    result.error("BUILD_INFO_ERROR", "Failed to get commit hash: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
