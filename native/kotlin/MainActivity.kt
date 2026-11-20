package com.example.assistant_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
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
                    "hasHeadphones" -> {
                        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        var found = false
                        for (d in am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)) {
                            when (d.type) {
                                AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                                AudioDeviceInfo.TYPE_WIRED_HEADSET,
                                AudioDeviceInfo.TYPE_USB_HEADSET,
                                AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                                AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> found = true
                            }
                            if (Build.VERSION.SDK_INT >= 31 &&
                                d.type == AudioDeviceInfo.TYPE_BLE_HEADSET) found = true
                        }
                        result.success(found)
                    }
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
