package com.example.assistant_app

import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * "Hey Zoya" sunai dene par Flutter (Dart) ko khabar deta hai.
 * Flutter jaaga ho to seedha batata hai, warna Zoya app ko aage laata hai.
 */
object WakeBridge {
    /** MainActivity (Flutter jinda ho) tab ye set karti hai. */
    var sink: (() -> Unit)? = null

    /** Flutter band tha, app ko khola gaya: Dart shuru hote hi ye check karega. */
    @Volatile
    var pending = false

    fun fire(ctx: Context) {
        val s = sink
        if (s != null) {
            Handler(Looper.getMainLooper()).post { s() }
        } else {
            pending = true
            ZoyaAccessibilityService.instance?.launchSelf()
        }
    }
}
