package com.example.assistant_app

import android.Manifest
import android.app.NotificationManager
import android.net.Uri
import android.os.PowerManager
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
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zoya/control")
        channel.setMethodCallHandler { call, result ->
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
                    "startForeground" -> {
                        try {
                            val i = Intent(this, ZoyaForegroundService::class.java)
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(i)
                            else startService(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "stopForeground" -> {
                        stopService(Intent(this, ZoyaForegroundService::class.java))
                        result.success(true)
                    }
                    "requestNotif" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            requestPermissions(
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101
                            )
                        }
                        result.success(true)
                    }
                    "hasCamera" -> result.success(
                        checkSelfPermission(Manifest.permission.CAMERA) ==
                            PackageManager.PERMISSION_GRANTED
                    )
                    "hasNotif" -> {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        result.success(nm.areNotificationsEnabled())
                    }
                    "hasBattery" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "openBattery" -> {
                        startActivity(
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "requestAll" -> {
                        val list = mutableListOf(
                            Manifest.permission.RECORD_AUDIO,
                            Manifest.permission.CAMERA
                        )
                        if (Build.VERSION.SDK_INT >= 33) {
                            list.add(Manifest.permission.POST_NOTIFICATIONS)
                        }
                        requestPermissions(list.toTypedArray(), 103)
                        result.success(true)
                    }
                    "wakeStart" -> {
                        try {
                            val phrases = (call.arguments as? List<*>)
                                ?.map { it.toString() } ?: emptyList()
                            val i = Intent(this, ZoyaForegroundService::class.java)
                                .putExtra("phrases", phrases.toTypedArray())
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(i)
                            else startService(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "wakeStop" -> {
                        stopService(Intent(this, ZoyaForegroundService::class.java))
                        ZoyaForegroundService.status = "off"
                        result.success(true)
                    }
                    "wakePause" -> {
                        ZoyaForegroundService.instance?.pause()
                        result.success(true)
                    }
                    "wakeResume" -> {
                        ZoyaForegroundService.instance?.resume()
                        result.success(true)
                    }
                    "wakeStatus" -> result.success(ZoyaForegroundService.status)
                    "wakeConsumePending" -> {
                        val p = WakeBridge.pending
                        WakeBridge.pending = false
                        result.success(p)
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

        WakeBridge.sink = { channel.invokeMethod("onWake", null) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WakeBridge.sink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
