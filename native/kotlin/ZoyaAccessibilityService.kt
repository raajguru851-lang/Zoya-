package com.example.assistant_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/** Phone control ka asli kaam: home, back, scroll, tap, app kholna. */
class ZoyaAccessibilityService : AccessibilityService() {

    companion object {
        var instance: ZoyaAccessibilityService? = null
    }

    private var borderView: RainbowBorderView? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        refreshBorder()
    }

    override fun onUnbind(intent: Intent?): Boolean {
        hideBorder()
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        hideBorder()
        instance = null
        super.onDestroy()
    }

    /** Sara Active ON ho aur mic permission ho, tabhi rangeen border dikhao. */
    fun refreshBorder() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val active = prefs.getBoolean("flutter.zoya_active", false)
        val mic = checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        if (active && mic) showBorder() else hideBorder()
    }

    private fun showBorder() {
        if (borderView != null) return
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val view = RainbowBorderView(this)
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        if (Build.VERSION.SDK_INT >= 28) {
            lp.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        try {
            wm.addView(view, lp)
            borderView = view
        } catch (e: Exception) {
            borderView = null
        }
    }

    private fun hideBorder() {
        val view = borderView ?: return
        try {
            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
        } catch (e: Exception) {
        }
        borderView = null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    /** Wake word par Sara app ko aage lao (Flutter band ho tab). */
    fun launchSelf() {
        try {
            val i = Intent(this, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            startActivity(i)
        } catch (e: Exception) {
        }
    }

    fun home(): Boolean = performGlobalAction(GLOBAL_ACTION_HOME)
    fun back(): Boolean = performGlobalAction(GLOBAL_ACTION_BACK)
    fun recents(): Boolean = performGlobalAction(GLOBAL_ACTION_RECENTS)
    fun notifications(): Boolean = performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)

    /** down = true: neeche scroll (ungli neeche se upar). */
    fun scroll(down: Boolean): Boolean {
        val dm = resources.displayMetrics
        val w = dm.widthPixels.toFloat()
        val h = dm.heightPixels.toFloat()
        val path = Path()
        if (down) {
            path.moveTo(w / 2, h * 0.7f)
            path.lineTo(w / 2, h * 0.3f)
        } else {
            path.moveTo(w / 2, h * 0.3f)
            path.lineTo(w / 2, h * 0.7f)
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 300))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    /** Screen par jis button/text par ye likha ho usko tap karo. */
    // ---------- Suraksha: paise/bank wali apps me kuch nahi karna ----------
    private val blockedWords = listOf(
        "paisa", "phonepe", "paytm", "npci", "upi", "bank", "wallet",
        "bhim", "razorpay", "payments", "finance"
    )

    private fun isBlocked(pkg: String): Boolean =
        blockedWords.any { pkg.lowercase().contains(it) }

    private fun blockedNow(): Boolean =
        isBlocked(rootInActiveWindow?.packageName?.toString() ?: "")

    /** Screen par jo dikh raha hai uski list (text, tap ho sakta hai ya nahi, jagah). */
    fun readScreen(): String {
        val root = rootInActiveWindow ?: return "screen nahi padh paayi"
        val pkg = root.packageName?.toString() ?: ""
        if (isBlocked(pkg)) {
            return "Ye app paise ya bank se judi lagti hai ($pkg), yahan main screen nahi padhungi."
        }
        val out = StringBuilder("App: $pkg\n")
        var count = 0
        val r = Rect()
        fun walk(n: AccessibilityNodeInfo?, depth: Int) {
            if (n == null || count >= 70 || depth > 30) return
            val label = (n.text?.toString() ?: "").ifBlank { n.contentDescription?.toString() ?: "" }
            if (label.isNotBlank() && n.isVisibleToUser) {
                n.getBoundsInScreen(r)
                val tags = buildString {
                    if (n.isClickable) append("tap ")
                    if (n.isEditable) append("input ")
                }.trim()
                out.append("- ${label.take(80)}")
                if (tags.isNotEmpty()) out.append(" [$tags]")
                out.append(" @(${r.centerX()},${r.centerY()})\n")
                count++
            }
            for (i in 0 until n.childCount) walk(n.getChild(i), depth + 1)
        }
        walk(root, 0)
        return out.toString()
    }

    /** Screen par (x, y) jagah tap karo. */
    fun tapXY(x: Float, y: Float): Boolean {
        if (blockedNow()) return false
        val p = Path().apply { moveTo(x, y) }
        val g = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(p, 0, 60))
            .build()
        return dispatchGesture(g, null, null)
    }

    private fun findEditable(n: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (n == null) return null
        if (n.isEditable) return n
        for (i in 0 until n.childCount) {
            val r = findEditable(n.getChild(i))
            if (r != null) return r
        }
        return null
    }

    /** Jahan cursor ho (ya pehle text box me) text likho. */
    fun typeText(text: String): Boolean {
        if (blockedNow()) return false
        val root = rootInActiveWindow ?: return false
        val target = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            ?: findEditable(root) ?: return false
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return target.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    /** Text box me Enter / Search dabao (Android 11+). */
    fun submit(): Boolean {
        if (blockedNow()) return false
        val root = rootInActiveWindow ?: return false
        val target = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            ?: findEditable(root) ?: return false
        return if (Build.VERSION.SDK_INT >= 30) {
            target.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
        } else {
            false
        }
    }

    fun tapText(text: String): Boolean {
        if (text.isBlank()) return false
        if (blockedNow()) return false
        val root = rootInActiveWindow ?: return false
        val nodes = root.findAccessibilityNodeInfosByText(text)
        for (n in nodes) {
            var cur: AccessibilityNodeInfo? = n
            while (cur != null) {
                if (cur.isClickable) {
                    return cur.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
                cur = cur.parent
            }
        }
        return false
    }

    /** App ka naam (jaise "WhatsApp") likho, wo khul jayegi. */
    fun openApp(name: String): Boolean {
        val q = name.trim().lowercase()
        if (q.isEmpty()) return false
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = pm.queryIntentActivities(intent, 0)
        val match = apps.firstOrNull { it.loadLabel(pm).toString().lowercase() == q }
            ?: apps.firstOrNull { it.loadLabel(pm).toString().lowercase().contains(q) }
            ?: return false
        val launch = pm.getLaunchIntentForPackage(match.activityInfo.packageName)
            ?: return false
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(launch)
        return true
    }
}
