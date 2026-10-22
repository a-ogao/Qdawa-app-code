package com.quikdawa

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val installerChannel = "com.quikdawa/installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            installerChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInstallerPackageName") {
                try {
                    result.success(installerPackageNameCompat())
                } catch (e: Exception) {
                    result.error("INSTALLER_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installerPackageNameCompat(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }
    }
}









