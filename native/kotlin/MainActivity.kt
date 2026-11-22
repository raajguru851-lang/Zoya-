package com.example.assistant_app

import android.Manifest
import android.content.IntentFilter
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.provider.AlarmClock
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
                            val args = call.arguments as? Map<*, *>
                            val phrases = (args?.get("phrases") as? List<*>)
                                ?.map { it.toString() } ?: emptyList()
                            val free = args?.get("free") as? Boolean ?: true
                            val i = Intent(this, ZoyaForegroundService::class.java)
                                .putExtra("phrases", phrases.toTypedArray())
                                .putExtra("free", free)
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(i)
                            else startService(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "keepAliveStart" -> {
                        try {
                            val i = Intent(this, ZoyaForegroundService::class.java)
                                .putExtra("keepalive", true)
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(i)
                            else startService(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "keepAliveStop" -> {
                        ZoyaForegroundService.instance?.releaseKeepAlive()
                        result.success(true)
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
                    "wakeHeard" -> result.success(ZoyaForegroundService.heard)
                    "wakeConsumePending" -> {
                        val p = WakeBridge.pending
                        WakeBridge.pending = false
                        result.success(p)
                    }
                    "phoneTool" -> {
                        val a = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        result.success(runTool(a))
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

    /** Activity shuru karo. Accessibility chal rahi ho to uske zariye (background me bhi). */
    private fun launch(i: Intent): Boolean {
        return try {
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            (ZoyaAccessibilityService.instance ?: this).startActivity(i)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Alarm, timer, torch, volume, call, link, WhatsApp, battery jaise chhote kaam. */
    private fun runTool(a: Map<*, *>): String {
        val name = a["name"]?.toString() ?: return "tool ka naam nahi mila"
        fun s(k: String): String = a[k]?.toString() ?: ""
        fun n(k: String): Int = (a[k] as? Number)?.toInt() ?: s(k).toIntOrNull() ?: 0

        return try {
            when (name) {
                "set_alarm" -> {
                    val label = s("label").ifEmpty { "Sara" }
                    val i = Intent(AlarmClock.ACTION_SET_ALARM)
                        .putExtra(AlarmClock.EXTRA_HOUR, n("hour"))
                        .putExtra(AlarmClock.EXTRA_MINUTES, n("minute"))
                        .putExtra(AlarmClock.EXTRA_MESSAGE, label)
                        .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                    if (launch(i)) "alarm laga diya: ${n("hour")}:${"%02d".format(n("minute"))}"
                    else "alarm nahi laga"
                }
                "set_timer" -> {
                    val i = Intent(AlarmClock.ACTION_SET_TIMER)
                        .putExtra(AlarmClock.EXTRA_LENGTH, n("seconds"))
                        .putExtra(AlarmClock.EXTRA_MESSAGE, s("label").ifEmpty { "Sara" })
                        .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                    if (launch(i)) "timer laga diya: ${n("seconds")} second" else "timer nahi laga"
                }
                "flashlight" -> {
                    val cm = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                    val id = cm.cameraIdList.firstOrNull {
                        cm.getCameraCharacteristics(it)
                            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                    } ?: return "is phone me flashlight nahi hai"
                    val on = (a["on"] as? Boolean) ?: true
                    cm.setTorchMode(id, on)
                    if (on) "flashlight on" else "flashlight off"
                }
                "set_volume" -> {
                    val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    when (s("action")) {
                        "up" -> am.adjustStreamVolume(
                            AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE,
                            AudioManager.FLAG_SHOW_UI
                        )
                        "down" -> am.adjustStreamVolume(
                            AudioManager.STREAM_MUSIC, AudioManager.ADJUST_LOWER,
                            AudioManager.FLAG_SHOW_UI
                        )
                        "mute" -> am.adjustStreamVolume(
                            AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE,
                            AudioManager.FLAG_SHOW_UI
                        )
                        "set" -> {
                            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            val level = max * n("percent").coerceIn(0, 100) / 100
                            am.setStreamVolume(
                                AudioManager.STREAM_MUSIC, level, AudioManager.FLAG_SHOW_UI
                            )
                        }
                        else -> return "ye volume action nahi hai"
                    }
                    "volume badal diya"
                }
                "dial_number" -> {
                    val num = s("number").filter { it.isDigit() || it == '+' }
                    if (num.isEmpty()) return "number nahi mila"
                    if (launch(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$num"))))
                        "dialer khol diya, call khud dabana hoga"
                    else "dialer nahi khula"
                }
                "web_search" -> {
                    val url = "https://www.google.com/search?q=" + Uri.encode(s("query"))
                    if (launch(Intent(Intent.ACTION_VIEW, Uri.parse(url)))) "search khol diya"
                    else "search nahi khula"
                }
                "open_link" -> {
                    var url = s("url").trim()
                    if (url.isEmpty()) return "link nahi mila"
                    if (!url.startsWith("http")) url = "https://$url"
                    if (launch(Intent(Intent.ACTION_VIEW, Uri.parse(url)))) "link khol diya"
                    else "link nahi khula"
                }
                "whatsapp_message" -> {
                    val phone = s("phone").filter { it.isDigit() }
                    val url = "https://wa.me/$phone?text=" + Uri.encode(s("text"))
                    if (launch(Intent(Intent.ACTION_VIEW, Uri.parse(url))))
                        "WhatsApp me message likhkar khol diya, bhejna user ko hai"
                    else "WhatsApp nahi khula"
                }
                "battery_status" -> {
                    val st = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val level = st?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                    val scale = st?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
                    val status = st?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                    val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL
                    val pct = if (level >= 0 && scale > 0) level * 100 / scale else -1
                    "battery $pct%, " + (if (charging) "charge ho rahi hai" else "charge nahi ho rahi")
                }
                else -> "ye tool nahi hai"
            }
        } catch (e: Exception) {
            "nahi ho paya: ${e.message}"
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WakeBridge.sink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
