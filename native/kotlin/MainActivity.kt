package com.example.assistant_app

import android.Manifest
import java.io.File
import android.app.SearchManager
import android.provider.MediaStore
import android.telecom.TelecomManager
import android.view.KeyEvent
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
                    "hasCall" -> result.success(
                        checkSelfPermission(Manifest.permission.CALL_PHONE) ==
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
                            Manifest.permission.CAMERA,
                            Manifest.permission.CALL_PHONE
                        )
                        if (Build.VERSION.SDK_INT >= 26) {
                            list.add(Manifest.permission.ANSWER_PHONE_CALLS)
                        }
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
                    "guardStart" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            val i = Intent(this, GuardService::class.java)
                                .putExtra("owner", args?.get("owner")?.toString() ?: "")
                                .putExtra("sens", (args?.get("sens") as? Number)?.toInt() ?: 1)
                                .putExtra("delay", (args?.get("delay") as? Number)?.toInt() ?: 3)
                                .putExtra("action", args?.get("action")?.toString() ?: "arm")
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(i)
                            else startService(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "guardStop" -> {
                        val g = GuardService.instance
                        if (g != null) g.disarm()
                        else stopService(Intent(this, GuardService::class.java))
                        GuardService.status = "idle"
                        result.success(true)
                    }
                    "guardStatus" -> result.success(GuardService.status)
                    "guardPhotos" -> {
                        val files = GuardService.photosDir(this).listFiles()
                            ?.filter { it.extension == "jpg" }
                            ?.sortedByDescending { it.lastModified() }
                            ?.map { it.absolutePath } ?: emptyList()
                        result.success(files)
                    }
                    "guardDeletePhoto" -> {
                        val p = call.arguments?.toString()
                        if (p != null) {
                            val f = File(p)
                            if (f.parentFile == GuardService.photosDir(this)) f.delete()
                        }
                        result.success(true)
                    }
                    "guardClearPhotos" -> {
                        GuardService.photosDir(this).listFiles()?.forEach { it.delete() }
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
                "make_call" -> {
                    val num = s("number").filter { it.isDigit() || it == '+' }
                    if (num.isEmpty()) return "number nahi mila"
                    if (checkSelfPermission(Manifest.permission.CALL_PHONE) !=
                        PackageManager.PERMISSION_GRANTED
                    ) return "Call ki permission nahi hai. App permissions me Phone calls allow karo."
                    if (launch(Intent(Intent.ACTION_CALL, Uri.parse("tel:$num")))) "call laga di"
                    else "call nahi lagi"
                }
                "answer_call" -> {
                    if (Build.VERSION.SDK_INT < 26) return "is Android par call uthana mumkin nahi"
                    if (checkSelfPermission(Manifest.permission.ANSWER_PHONE_CALLS) !=
                        PackageManager.PERMISSION_GRANTED
                    ) return "Call uthane ki permission nahi hai. App permissions me Phone calls allow karo."
                    val tm = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    tm.acceptRingingCall()
                    "call utha li"
                }
                "end_call" -> {
                    if (Build.VERSION.SDK_INT < 28) return "is Android par call kaatna mumkin nahi"
                    if (checkSelfPermission(Manifest.permission.ANSWER_PHONE_CALLS) !=
                        PackageManager.PERMISSION_GRANTED
                    ) return "Call kaatne ki permission nahi hai. App permissions me Phone calls allow karo."
                    val tm = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    if (tm.endCall()) "call kaat di" else "abhi koi call nahi chal rahi"
                }
                "play_music" -> {
                    val q = s("query")
                    val i = Intent(MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH)
                        .putExtra(SearchManager.QUERY, q)
                        .putExtra(MediaStore.EXTRA_MEDIA_FOCUS, "vnd.android.cursor.item/*")
                    if (launch(i)) {
                        "music app me '$q' chalane ki koshish ki. Na chale to read_screen se dekho aur tap_text se gaana dabao."
                    } else {
                        val url = "https://www.youtube.com/results?search_query=" + Uri.encode(q)
                        if (launch(Intent(Intent.ACTION_VIEW, Uri.parse(url))))
                            "YouTube par '$q' search khol diya. Ab read_screen se dekhkar pehla gaana tap_text ya tap_xy se dabao."
                        else "music nahi khula"
                    }
                }
                "media_control" -> {
                    val code = when (s("action")) {
                        "play", "pause", "play_pause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                        "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                        "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                        "stop" -> KeyEvent.KEYCODE_MEDIA_STOP
                        else -> return "ye media action nahi hai"
                    }
                    val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, code))
                    am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, code))
                    "media key bhej di"
                }
                "read_screen" ->
                    ZoyaAccessibilityService.instance?.readScreen() ?: "Accessibility ON nahi hai"
                "tap_xy" -> {
                    val svc = ZoyaAccessibilityService.instance ?: return "Accessibility ON nahi hai"
                    if (svc.tapXY(n("x").toFloat(), n("y").toFloat())) "tap kar diya"
                    else "tap nahi hua (ya ye app surakshit list me hai)"
                }
                "type_text" -> {
                    val svc = ZoyaAccessibilityService.instance ?: return "Accessibility ON nahi hai"
                    if (svc.typeText(s("text"))) "text likh diya" else "text nahi likha gaya"
                }
                "submit_text" -> {
                    val svc = ZoyaAccessibilityService.instance ?: return "Accessibility ON nahi hai"
                    if (svc.submit()) "enter dab gaya" else "enter nahi dab paya"
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
