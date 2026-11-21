package com.example.assistant_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import org.vosk.android.StorageService

/**
 * Background me Zoya ko zinda rakhta hai aur offline (Vosk) se
 * "Hey Zoya" jaisa wake word sunta rehta hai. Android ke niyam se iski
 * notification hamesha dikhti hai.
 */
class ZoyaForegroundService : Service(), RecognitionListener {

    companion object {
        var instance: ZoyaForegroundService? = null

        /** off, loading, listening, paused, awake, error: ... */
        @Volatile
        var status: String = "off"

        private const val PREFS = "zoya_native"
    }

    private val channelId = "zoya_listening"
    private val handler = Handler(Looper.getMainLooper())

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speech: SpeechService? = null
    private var phrases: List<String> = listOf("hey zoya")
    private var triggered = false
    private var wantListening = false

    private val safety = Runnable { if (triggered) resume() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this

        if (!startAsForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }

        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        val given = intent?.getStringArrayExtra("phrases")
        if (given != null && given.isNotEmpty()) {
            phrases = given.map { it.trim().lowercase() }.filter { it.isNotEmpty() }
            prefs.edit().putString("phrases", phrases.joinToString("|")).apply()
        } else {
            prefs.getString("phrases", null)?.let { saved ->
                phrases = saved.split("|").filter { it.isNotEmpty() }
            }
        }
        if (phrases.isEmpty()) phrases = listOf("hey zoya")

        rebuildAndListen()
        return START_STICKY
    }

    private fun startAsForeground(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 26) {
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.createNotificationChannel(
                    NotificationChannel(channelId, "Zoya", NotificationManager.IMPORTANCE_LOW)
                )
            }
            val open = PendingIntent.getActivity(
                this, 0,
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE
            )
            val builder =
                if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channelId)
                else Notification.Builder(this)
            val notification = builder
                .setContentTitle("Zoya active hai")
                .setContentText("\"Hey Zoya\" bolkar jagao")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentIntent(open)
                .setOngoing(true)
                .build()
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            } else {
                startForeground(1, notification)
            }
            true
        } catch (e: Exception) {
            status = "error: foreground ${e.message}"
            false
        }
    }

    // ------------------------- Vosk -------------------------

    private fun rebuildAndListen() {
        wantListening = true
        triggered = false
        handler.removeCallbacks(safety)
        status = "loading"
        stopListening()
        try { recognizer?.close() } catch (e: Exception) {}
        recognizer = null

        val m = model
        if (m != null) {
            startRecognizer(m)
            return
        }
        StorageService.unpack(
            this, "model-en-us", "model",
            { loaded: Model ->
                model = loaded
                handler.post { startRecognizer(loaded) }
            },
            { e: java.io.IOException -> status = "error: model ${e.message}" }
        )
    }

    private fun startRecognizer(m: Model) {
        try {
            val grammar = JSONArray().apply {
                phrases.forEach { put(it) }
                put("[unk]")
            }.toString()
            recognizer = Recognizer(m, 16000.0f, grammar)
            startListening()
        } catch (e: Exception) {
            status = "error: ${e.message}"
        }
    }

    private fun startListening() {
        val r = recognizer ?: return
        try {
            speech = SpeechService(r, 16000.0f)
            speech?.startListening(this)
            status = "listening"
        } catch (e: Exception) {
            status = "error: mic ${e.message}"
        }
    }

    private fun stopListening() {
        try {
            speech?.stop()
            speech?.shutdown()
        } catch (e: Exception) {
        }
        speech = null
    }

    /** Dart ne conversation shuru ki: mic chhod do. */
    fun pause() {
        handler.removeCallbacks(safety)
        stopListening()
        status = "paused"
    }

    /** Conversation khatam: dobara wake word sunna shuru. */
    fun resume() {
        handler.removeCallbacks(safety)
        triggered = false
        if (wantListening && recognizer != null) {
            try { recognizer?.reset() } catch (e: Exception) {}
            stopListening()
            startListening()
        }
    }

    private fun check(json: String?) {
        if (triggered || json == null) return
        val text = try {
            val o = JSONObject(json)
            o.optString("partial", o.optString("text", ""))
        } catch (e: Exception) {
            ""
        }
        if (text.isBlank()) return
        if (phrases.any { text.contains(it) }) trigger()
    }

    private fun trigger() {
        triggered = true
        stopListening()
        status = "awake"
        WakeBridge.fire(this)
        // Dart jawab na de to 8 second baad wapas sunna shuru
        handler.postDelayed(safety, 8000)
    }

    override fun onPartialResult(hypothesis: String?) = check(hypothesis)
    override fun onResult(hypothesis: String?) = check(hypothesis)
    override fun onFinalResult(hypothesis: String?) {}
    override fun onError(exception: Exception?) {
        status = "error: ${exception?.message}"
    }

    override fun onTimeout() {}

    override fun onDestroy() {
        wantListening = false
        handler.removeCallbacks(safety)
        stopListening()
        try { recognizer?.close() } catch (e: Exception) {}
        try { model?.close() } catch (e: Exception) {}
        recognizer = null
        model = null
        status = "off"
        instance = null
        super.onDestroy()
    }
}
