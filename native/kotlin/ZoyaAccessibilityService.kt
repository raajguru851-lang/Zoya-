package com.example.assistant_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/** Phone control ka asli kaam: home, back, scroll, tap, app kholna. */
class ZoyaAccessibilityService : AccessibilityService() {

    companion object {
        var instance: ZoyaAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

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
    fun tapText(text: String): Boolean {
        if (text.isBlank()) return false
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
