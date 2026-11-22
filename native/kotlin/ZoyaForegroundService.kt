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
 * Background me Sara ko zinda rakhta hai aur offline (Vosk) se
 * "Hey Sara" jaisa wake word sunta rehta hai. Android ke niyam se iski
 * notification hamesha dikhti hai.
 */
class ZoyaForegroundService : Service(), RecognitionListener {

    companion object {
        var instance: ZoyaForegroundService? = null

        /** off, loading, listening, paused, awake, error: ... */
        @Volatile
        var status: String = "off"

        /** Vosk ne aakhri baar kya suna (jaanch ke liye). */
        @Volatile
        var heard: String = ""

        /** Voice session chal raha hai: service zinda rakho (background me mic ke liye). */
        @Volatile
        var keepAlive = false

        private const val PREFS = "zoya_native"
    }

    private val channelId = "zoya_listening"
    private val handler = Handler(Looper.getMainLooper())

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speech: SpeechService? = null
    private var phrases: List<String> = listOf("hey sara")
    private var free = true

    // "Sara" naam model ko aksar thoda alag sunai deta hai (sarah, zara...)
    // Grammar me ye sab jode jaate hain, taaki "wake up ___" pakda jaye.
    private val nameVariants = listOf(
        "sara", "sarah", "zara", "sera", "cera", "sarra", "sar a", "sahra", "sora"
    )

    // Sab-suno mode me inme se koi naam sunai de to bhi jaag jao
    private val strictNames = listOf("sara", "sarah", "zara", "sera", "sarra", "cera")

    /** "wake up sara" jaise 3+ shabd ke wake phrase ka shuruaati hissa ("wake up"). */
    private fun anchors(): List<String> = phrases.mapNotNull { p ->
        val w = p.split(" ").filter { it.isNotEmpty() }
        if (w.size >= 3) w.dropLast(1).joinToString(" ") else null
    }.distinct()

    private fun grammarList(): List<String> {
        val g = LinkedHashSet<String>()
        g.addAll(phrases)
        for (a in anchors()) {
            g.add(a)
            nameVariants.forEach { g.add("$a $it") }
        }
        return g.toList()
    }
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

        // Sirf Voice session ke liye zinda rakhna (wake word sunna nahi)
        if (intent?.getBooleanExtra("keepalive", false) == true) {
            keepAlive = true
            return if (wantListening) START_STICKY else START_NOT_STICKY
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
        if (phrases.isEmpty()) phrases = listOf("hey sara")

        if (intent != null && intent.hasExtra("free")) {
            free = intent.getBooleanExtra("free", true)
            prefs.edit().putBoolean("free", free).apply()
        } else {
            free = prefs.getBoolean("free", true)
        }

        rebuildAndListen()
        return START_STICKY
    }

    private fun startAsForeground(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 26) {
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.createNotificationChannel(
                    NotificationChannel(channelId, "Sara", NotificationManager.IMPORTANCE_LOW)
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
                .setContentTitle("Sara active hai")
                .setContentText("\"Wake up Sara\" bolkar jagao")
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
                grammarList().forEach { put(it) }
                put("[unk]")
            }.toString()
            // free: sab kuch sunta hai (jaanch/aasaan), warna sirf wake shabd (halka)
            recognizer =
                if (free) Recognizer(m, 16000.0f) else Recognizer(m, 16000.0f, grammar)
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

    /** Voice session khatam. Wake word na sun rahe ho to service band. */
    fun releaseKeepAlive() {
        keepAlive = false
        if (!wantListening) stopSelf()
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
        heard = text
        if (matches(text)) trigger()
    }

    private fun matches(t: String): Boolean {
        if (phrases.any { t.contains(it) }) return true
        // "wake up" sunte hi jaag jao (naam kuch bhi sunai de)
        if (anchors().any { t.contains(it) }) return true
        return free && strictNames.any { t.contains(it) }
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
