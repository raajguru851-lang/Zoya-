package com.example.assistant_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.ImageFormat
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.ImageReader
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import java.io.File
import java.util.Locale
import kotlin.math.sqrt

/**
 * Touch Guard: phone lock karke chhodo. Koi phone utha le ya hilaye to
 * siren bajta hai, front camera se photo khichti hai, aur awaaz me chetavni
 * aati hai. Maalik ke unlock karte hi sab band.
 *
 * Halat: idle, waiting (screen band hone ka intezaar), grace (10 second),
 * armed (nigrani), trigger (chetavni ka mauka), alarm (siren).
 */
class GuardService : Service(), SensorEventListener {

    companion object {
        var instance: GuardService? = null

        @Volatile
        var status: String = "idle"

        fun photosDir(ctx: Context): File =
            File(ctx.filesDir, "intruders").apply { mkdirs() }
    }

    private val channelId = "zoya_guard"
    private val handler = Handler(Looper.getMainLooper())

    private var owner = "Mr ZX KD"
    private var threshold = 1.8f
    private var entryDelayMs = 3000L

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private val siren = Siren()
    private var wakeLock: PowerManager.WakeLock? = null

    private var lp: FloatArray? = null
    private var base: FloatArray? = null
    private var settle = 0
    private var hits = 0
    private var receiversOn = false
    private var photoRounds = 0
    private val currentPhotos = mutableListOf<File>()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            when (i?.action) {
                Intent.ACTION_SCREEN_OFF -> if (status == "waiting") startGrace()
                Intent.ACTION_SCREEN_ON -> if (status == "grace") {
                    handler.removeCallbacks(armRunnable)
                    setState("waiting")
                }
                Intent.ACTION_USER_PRESENT -> disarm()
            }
        }
    }

    private val armRunnable = Runnable { arm() }
    private val alarmRunnable = Runnable {
        if (status == "trigger") {
            setState("alarm")
            alarmLoop()
            scheduleMorePhotos()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        if (!startAsForeground("Guard chalu ho raha hai")) {
            stopSelf()
            return START_NOT_STICKY
        }

        val o = intent?.getStringExtra("owner") ?: ""
        owner = if (o.isBlank()) "Mr ZX KD" else o
        threshold = when (intent?.getIntExtra("sens", 1)) {
            0 -> 3.0f
            2 -> 1.0f
            else -> 1.8f
        }
        entryDelayMs = (intent?.getIntExtra("delay", 3) ?: 3) * 1000L

        initTts()

        if (intent?.getStringExtra("action") == "test") {
            runTest()
            return START_NOT_STICKY
        }

        registerReceivers()
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        if (pm.isInteractive) setState("waiting") else startGrace()
        return START_NOT_STICKY
    }

    // ------------------------- halat -------------------------

    private fun setState(s: String) {
        status = s
        val text = when (s) {
            "waiting" -> "Phone lock karo, 10 second baad guard lagega"
            "grace" -> "Guard lag raha hai..."
            "armed" -> "Guard chalu hai. Phone ko mat chhuo."
            "trigger" -> "Kuch hila! Unlock karo warna siren bajega."
            "alarm" -> "Kisi ne phone chhua! Photo kheechi gayi."
            else -> "Guard"
        }
        try {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(2, buildNotification(text))
        } catch (e: Exception) {
        }
    }

    private fun startGrace() {
        setState("grace")
        handler.removeCallbacks(armRunnable)
        handler.postDelayed(armRunnable, 10_000)
    }

    private fun arm() {
        val sm = getSystemService(SENSOR_SERVICE) as SensorManager
        val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (accel == null) {
            setState("idle")
            shutdown()
            return
        }
        lp = null
        base = null
        settle = 0
        hits = 0
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "sara:guard").apply {
                acquire(12 * 60 * 60 * 1000L)
            }
        } catch (e: Exception) {
        }
        sm.registerListener(this, accel, SensorManager.SENSOR_DELAY_UI)
        setState("armed")
    }

    override fun onSensorChanged(e: SensorEvent?) {
        if (e == null || status != "armed") return
        val v = e.values
        val cur = lp
        if (cur == null) {
            lp = floatArrayOf(v[0], v[1], v[2])
            return
        }
        // halka filter: kampan (vibration) hat jata hai, uthana/hilana bachta hai
        for (i in 0..2) cur[i] = cur[i] * 0.75f + v[i] * 0.25f

        if (settle < 20) {
            settle++
            base = cur.copyOf()
            return
        }
        val b = base ?: return
        val dx = cur[0] - b[0]
        val dy = cur[1] - b[1]
        val dz = cur[2] - b[2]
        val d = sqrt(dx * dx + dy * dy + dz * dz)
        hits = if (d > threshold) hits + 1 else 0
        if (hits >= 2) trigger()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun trigger() {
        if (status != "armed") return
        try {
            (getSystemService(SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        } catch (e: Exception) {
        }
        setState("trigger")
        currentPhotos.clear()
        photoRounds = 0
        captureIntruder()
        handler.postDelayed(alarmRunnable, entryDelayMs)
    }

    /** Maalik ne unlock kiya, ya app se band kiya. */
    fun disarm() {
        if (status == "trigger") {
            // maalik ne chetavni ke mauke me unlock kiya: ye photos hata do
            currentPhotos.forEach { try { it.delete() } catch (e: Exception) {} }
        }
        shutdown()
    }

    private fun shutdown() {
        handler.removeCallbacksAndMessages(null)
        siren.stop()
        try { tts?.stop(); tts?.shutdown() } catch (e: Exception) {}
        tts = null
        ttsReady = false
        try {
            (getSystemService(SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        } catch (e: Exception) {
        }
        try { wakeLock?.let { if (it.isHeld) it.release() } } catch (e: Exception) {}
        wakeLock = null
        if (receiversOn) {
            try { unregisterReceiver(receiver) } catch (e: Exception) {}
            receiversOn = false
        }
        status = "idle"
        try {
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(2)
        } catch (e: Exception) {
        }
        try {
            if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_REMOVE)
            else stopForeground(true)
        } catch (e: Exception) {
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        siren.stop()
        try { tts?.shutdown() } catch (e: Exception) {}
        try {
            (getSystemService(SENSOR_SERVICE) as SensorManager).unregisterListener(this)
        } catch (e: Exception) {
        }
        try { wakeLock?.let { if (it.isHeld) it.release() } } catch (e: Exception) {}
        if (receiversOn) {
            try { unregisterReceiver(receiver) } catch (e: Exception) {}
            receiversOn = false
        }
        status = "idle"
        instance = null
        super.onDestroy()
    }

    private fun registerReceivers() {
        if (receiversOn) return
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(receiver, f, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, f)
        }
        receiversOn = true
    }

    // ------------------------- siren aur awaaz -------------------------

    private fun boostVolume() {
        try {
            val am = getSystemService(AUDIO_SERVICE) as AudioManager
            am.setStreamVolume(
                AudioManager.STREAM_ALARM, am.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0
            )
        } catch (e: Exception) {
        }
    }

    private fun initTts() {
        if (tts != null) return
        tts = TextToSpeech(this) { st -> ttsReady = st == TextToSpeech.SUCCESS }
    }

    private fun speakWarning() {
        val t = tts ?: return
        if (!ttsReady) return
        val hindi = try {
            t.isLanguageAvailable(Locale("hi", "IN")) >= TextToSpeech.LANG_AVAILABLE
        } catch (e: Exception) {
            false
        }
        val text: String
        if (hindi) {
            t.setLanguage(Locale("hi", "IN"))
            text = "यह $owner का फ़ोन है। कृपया इसे वापस रख दो।"
        } else {
            t.setLanguage(Locale.ENGLISH)
            text = "This is $owner's phone. Please put it back."
        }
        val p = Bundle().apply {
            putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_ALARM)
        }
        t.speak(text, TextToSpeech.QUEUE_FLUSH, p, "guard")
    }

    /** 7 second siren, phir chetavni ki awaaz, aur dohrao. */
    private fun alarmLoop() {
        if (status != "alarm") return
        boostVolume()
        siren.start()
        handler.postDelayed({
            if (status != "alarm") return@postDelayed
            siren.stop()
            speakWarning()
            handler.postDelayed({ alarmLoop() }, 6000)
        }, 7000)
    }

    private fun runTest() {
        status = "test"
        boostVolume()
        siren.start()
        handler.postDelayed({
            siren.stop()
            speakWarning()
            handler.postDelayed({ shutdown() }, 6000)
        }, 4000)
    }

    private class Siren {
        @Volatile
        private var running = false

        fun start() {
            if (running) return
            running = true
            Thread {
                val sr = 22050
                val minBuf = AudioTrack.getMinBufferSize(
                    sr, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT
                )
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sr)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(minBuf * 2)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()
                track.play()
                val buf = ShortArray(sr / 10)
                var phase = 0.0
                var t = 0.0
                while (running) {
                    for (i in buf.indices) {
                        // 700 se 1500 Hz tak upar-neeche ghoomti tez awaaz
                        val f = 1100.0 + 400.0 * Math.sin(2.0 * Math.PI * t)
                        phase += 2.0 * Math.PI * f / sr
                        buf[i] = if (Math.sin(phase) >= 0) 28000 else -28000
                        t += 1.0 / sr
                    }
                    track.write(buf, 0, buf.size)
                }
                try { track.stop() } catch (e: Exception) {}
                track.release()
            }.start()
        }

        fun stop() {
            running = false
        }
    }

    // ------------------------- photo -------------------------

    private fun scheduleMorePhotos() {
        handler.postDelayed({
            if (status == "alarm" && photoRounds < 4) {
                captureIntruder()
                scheduleMorePhotos()
            }
        }, 25_000)
    }

    private fun saveJpeg(bytes: ByteArray) {
        try {
            val dir = photosDir(this)
            val f = File(dir, "intruder_${System.currentTimeMillis()}.jpg")
            f.writeBytes(bytes)
            synchronized(currentPhotos) { currentPhotos.add(f) }
            // sirf aakhri 30 photos rakho
            val all = dir.listFiles()?.sortedBy { it.lastModified() } ?: return
            if (all.size > 30) all.take(all.size - 30).forEach { it.delete() }
        } catch (e: Exception) {
        }
    }

    /** Front camera se chhupkar 2 photo kheencho (screen band hone par bhi). */
    private fun captureIntruder() {
        photoRounds++
        if (checkSelfPermission(android.Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
        ) return
        try {
            val cm = getSystemService(CAMERA_SERVICE) as CameraManager
            val id = cm.cameraIdList.firstOrNull {
                cm.getCameraCharacteristics(it)
                    .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT
            } ?: cm.cameraIdList.firstOrNull() ?: return
            val ch = cm.getCameraCharacteristics(id)
            val map = ch.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) ?: return
            val jpegSizes = map.getOutputSizes(ImageFormat.JPEG) ?: return
            val jpegSize = jpegSizes.filter { it.width <= 1920 }
                .maxByOrNull { it.width * it.height } ?: jpegSizes[0]
            val yuvSizes = map.getOutputSizes(ImageFormat.YUV_420_888) ?: return
            val yuvSize = yuvSizes.filter { it.width <= 640 }
                .maxByOrNull { it.width * it.height } ?: yuvSizes[yuvSizes.size - 1]
            val orientation = ch.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 270

            val thread = HandlerThread("guard-cam").apply { start() }
            val h = Handler(thread.looper)
            val jpegReader = ImageReader.newInstance(jpegSize.width, jpegSize.height, ImageFormat.JPEG, 2)
            val yuvReader = ImageReader.newInstance(yuvSize.width, yuvSize.height, ImageFormat.YUV_420_888, 2)

            jpegReader.setOnImageAvailableListener({ r ->
                val img = r.acquireLatestImage() ?: return@setOnImageAvailableListener
                try {
                    val buf = img.planes[0].buffer
                    val bytes = ByteArray(buf.remaining())
                    buf.get(bytes)
                    saveJpeg(bytes)
                } finally {
                    img.close()
                }
            }, h)
            yuvReader.setOnImageAvailableListener({ r -> r.acquireLatestImage()?.close() }, h)

            cm.openCamera(id, object : CameraDevice.StateCallback() {
                override fun onOpened(cam: CameraDevice) {
                    try {
                        cam.createCaptureSession(
                            listOf(yuvReader.surface, jpegReader.surface),
                            object : CameraCaptureSession.StateCallback() {
                                override fun onConfigured(s: CameraCaptureSession) {
                                    try {
                                        val prev = cam.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                                            .apply { addTarget(yuvReader.surface) }.build()
                                        s.setRepeatingRequest(prev, null, h)
                                        val shoot = Runnable {
                                            try {
                                                val req = cam.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
                                                    .apply {
                                                        addTarget(jpegReader.surface)
                                                        set(CaptureRequest.JPEG_ORIENTATION, orientation)
                                                    }.build()
                                                s.capture(req, null, h)
                                            } catch (e: Exception) {
                                            }
                                        }
                                        h.postDelayed(shoot, 1200)
                                        h.postDelayed(shoot, 2400)
                                        h.postDelayed({
                                            try { s.close() } catch (e: Exception) {}
                                            try { cam.close() } catch (e: Exception) {}
                                            try { jpegReader.close() } catch (e: Exception) {}
                                            try { yuvReader.close() } catch (e: Exception) {}
                                            thread.quitSafely()
                                        }, 3800)
                                    } catch (e: Exception) {
                                        try { cam.close() } catch (x: Exception) {}
                                        thread.quitSafely()
                                    }
                                }

                                override fun onConfigureFailed(s: CameraCaptureSession) {
                                    try { cam.close() } catch (e: Exception) {}
                                    thread.quitSafely()
                                }
                            }, h
                        )
                    } catch (e: Exception) {
                        try { cam.close() } catch (x: Exception) {}
                        thread.quitSafely()
                    }
                }

                override fun onDisconnected(cam: CameraDevice) {
                    try { cam.close() } catch (e: Exception) {}
                    thread.quitSafely()
                }

                override fun onError(cam: CameraDevice, error: Int) {
                    try { cam.close() } catch (e: Exception) {}
                    thread.quitSafely()
                }
            }, h)
        } catch (e: Exception) {
        }
    }

    // ------------------------- notification -------------------------

    private fun buildNotification(text: String): Notification {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(channelId, "Sara Guard", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val open = PendingIntent.getActivity(
            this, 1,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channelId)
        else Notification.Builder(this)
        return b.setContentTitle("Sara Guard")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(open)
            .setOngoing(true)
            .build()
    }

    private fun startAsForeground(text: String): Boolean {
        return try {
            val n = buildNotification(text)
            if (Build.VERSION.SDK_INT >= 30) {
                startForeground(2, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
            } else {
                startForeground(2, n)
            }
            true
        } catch (e: Exception) {
            status = "error"
            false
        }
    }
}
