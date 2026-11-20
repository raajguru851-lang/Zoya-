package com.example.assistant_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zoya/control")
            .setMethodCallHandler { call, result ->
                val svc = ZoyaAccessibilityService.instance
                when (call.method) {
                    "isEnabled" -> result.success(svc != null)
                    "hasMic" -> result.success(
                        checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                            PackageManager.PERMISSION_GRANTED
                    )
                    "refreshBorder" -> {
                        svc?.refreshBorder()
                        result.success(svc != null)
                    }
                    "openSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    else -> {
                        if (svc == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val arg = call.arguments as? String ?: ""
                        val ok = when (call.method) {
                            "home" -> svc.home()
                            "back" -> svc.back()
                            "recents" -> svc.recents()
                            "notifications" -> svc.notifications()
                            "scrollDown" -> svc.scroll(true)
                            "scrollUp" -> svc.scroll(false)
                            "tapText" -> svc.tapText(arg)
                            "openApp" -> svc.openApp(arg)
                            else -> {
                                result.notImplemented()
                                return@setMethodCallHandler
                            }
                        }
                        result.success(ok)
                    }
                }
            }
    }
}
