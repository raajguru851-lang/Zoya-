package com.example.assistant_app

import android.app.Notification
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

/**
 * WhatsApp auto-reply: chune hue logon ke message par notification ke
 * "Reply" button se jawab bhejta hai. Jawab Gemini se bante hain.
 */
class SaraNotificationListener : NotificationListenerService() {

    companion object {
        private const val FLUTTER = "FlutterSharedPreferences"
        private const val NATIVE = "zoya_native"

        fun readLog(ctx: Context): String {
            val raw = ctx.getSharedPreferences(NATIVE, Context.MODE_PRIVATE)
                .getString("auto_log", "[]") ?: "[]"
            return try {
                val a = JSONArray(raw)
                (0 until a.length()).joinToString("\n") { a.getString(it) }
            } catch (e: Exception) {
                ""
            }
        }

        fun clearLog(ctx: Context) {
            ctx.getSharedPreferences(NATIVE, Context.MODE_PRIVATE)
                .edit().remove("auto_log").apply()
        }
    }

    private val pool = Executors.newSingleThreadExecutor()
    private val lastReply = HashMap<String, Long>()
    private val lastSeen = HashMap<String, String>()
    private var dayKey = ""
    private var dayCount = 0

    private val whatsapp = setOf("com.whatsapp", "com.whatsapp.w4b")

    // In shabdon wale message par kabhi jawab nahi bhejna
    private val sensitive = listOf(
        "otp", "password", "cvv", "upi", "bank", "account number",
        "verification code", "send money", "paise bhej", "transfer",
        "aadhaar", "aadhar", "atm", "pin number", "pin code"
    )

    private fun prefs() = getSharedPreferences(FLUTTER, Context.MODE_PRIVATE)

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            handle(sbn)
        } catch (e: Exception) {
            log("error: ${e.message}")
        }
    }

    private fun handle(sbn: StatusBarNotification) {
        if (sbn.packageName !in whatsapp) return
        val p = prefs()
        if (!p.getBoolean("flutter.auto_on", false)) return

        val n = sbn.notification
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val ex = n.extras
        // group chat me kabhi jawab nahi
        if (ex.getBoolean(Notification.EXTRA_IS_GROUP_CONVERSATION, false)) return
        if (ex.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE) != null) return

        val sender = ex.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: return
        val text = ex.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: return
        if (sender.isEmpty() || text.isEmpty() || sender.equals("WhatsApp", true)) return

        val action = n.actions?.firstOrNull { a -> a.remoteInputs?.isNotEmpty() == true } ?: return

        // wahi message dobara (notification update) ho to chhod do
        if (lastSeen[sender] == text) return
        lastSeen[sender] = text

        // kin logon ko jawab dena hai
        val allowAll = p.getBoolean("flutter.auto_all", false)
        val allowed = (p.getString("flutter.auto_contacts", "") ?: "")
            .split("\n").map { it.trim().lowercase() }.filter { it.isNotEmpty() }
        val s = sender.lowercase()
        if (!allowAll && allowed.none { it == s || s.contains(it) }) {
            log("chhoda ($sender): list me nahi")
            return
        }

        val low = text.lowercase()
        if (sensitive.any { low.contains(it) }) {
            log("chhoda ($sender): nijii/paise wali baat")
            return
        }

        val now = System.currentTimeMillis()
        val cool = try { p.getLong("flutter.auto_cooldown", 10L) } catch (e: Exception) { 10L }
        val last = lastReply[sender] ?: 0L
        if (now - last < cool * 60_000L) {
            log("chhoda ($sender): abhi hi jawab diya tha")
            return
        }

        val today = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())
        if (today != dayKey) {
            dayKey = today
            dayCount = 0
        }
        if (dayCount >= 60) {
            log("chhoda: aaj ke 60 jawab poore")
            return
        }

        pool.execute { reply(sender, text, action) }
    }

    private fun reply(sender: String, text: String, action: Notification.Action) {
        val p = prefs()
        var answer: String?
        if ((p.getString("flutter.auto_style", "ai") ?: "ai") == "fixed") {
            answer = p.getString("flutter.auto_fixed", "") ?: ""
        } else {
            val key = p.getString("flutter.gemini_api_key", "") ?: ""
            if (key.isEmpty()) {
                log("chhoda ($sender): Gemini key nahi hai")
                return
            }
            val model = p.getString("flutter.auto_model", "gemini-3.8-flash") ?: "gemini-3.8-flash"
            val persona = p.getString("flutter.auto_persona", "") ?: ""
            answer = askGemini(
                key, model, persona,
                "WhatsApp par \"$sender\" ne ye message bheja: \"$text\"\nUska jawab likho."
            )
        }
        if (answer.isNullOrBlank()) {
            log("jawab nahi ban paya ($sender)")
            return
        }
        answer = answer.trim().trim('"')
        if (answer.length > 400) answer = answer.take(400)
        val sig = p.getString("flutter.auto_sig", "") ?: ""
        val finalText = if (sig.isNotBlank()) "$answer\n$sig" else answer

        if (sendReply(action, finalText)) {
            lastReply[sender] = System.currentTimeMillis()
            dayCount++
            log("$sender: \"${text.take(60)}\" -> \"${answer.take(80)}\"")
        } else {
            log("jawab bhej nahi paya ($sender)")
        }
    }

    private fun sendReply(action: Notification.Action, text: String): Boolean {
        return try {
            val inputs = action.remoteInputs ?: return false
            val intent = Intent()
            val bundle = Bundle()
            for (ri in inputs) bundle.putCharSequence(ri.resultKey, text)
            RemoteInput.addResultsToIntent(inputs, intent, bundle)
            action.actionIntent.send(this, 0, intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun askGemini(key: String, model: String, system: String, user: String): String? {
        return try {
            val url = URL("https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("x-goog-api-key", key)
            conn.connectTimeout = 15000
            conn.readTimeout = 30000
            conn.doOutput = true
            val body = JSONObject()
                .put(
                    "system_instruction",
                    JSONObject().put("parts", JSONArray().put(JSONObject().put("text", system)))
                )
                .put(
                    "contents",
                    JSONArray().put(
                        JSONObject().put("role", "user")
                            .put("parts", JSONArray().put(JSONObject().put("text", user)))
                    )
                )
            conn.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            if (conn.responseCode != 200) {
                log("Gemini error ${conn.responseCode}")
                return null
            }
            val resp = conn.inputStream.bufferedReader().readText()
            val parts = JSONObject(resp).getJSONArray("candidates").getJSONObject(0)
                .getJSONObject("content").getJSONArray("parts")
            val sb = StringBuilder()
            for (i in 0 until parts.length()) sb.append(parts.getJSONObject(i).optString("text", ""))
            sb.toString()
        } catch (e: Exception) {
            log("Gemini dikkat: ${e.message}")
            null
        }
    }

    @Synchronized
    private fun log(line: String) {
        val sp = getSharedPreferences(NATIVE, Context.MODE_PRIVATE)
        val arr = try { JSONArray(sp.getString("auto_log", "[]")) } catch (e: Exception) { JSONArray() }
        val ts = SimpleDateFormat("dd/MM HH:mm", Locale.US).format(Date())
        val list = ArrayList<String>()
        for (i in 0 until arr.length()) list.add(arr.getString(i))
        list.add("$ts  $line")
        val keep = if (list.size > 40) list.subList(list.size - 40, list.size) else list
        sp.edit().putString("auto_log", JSONArray(keep).toString()).apply()
    }
}
