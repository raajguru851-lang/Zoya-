package com.example.assistant_app

import android.animation.ArgbEvaluator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.RectF
import android.view.View
import android.view.animation.LinearInterpolator

/** Poori screen ke kinare par ghoomti 12 rangon ki line (Zoya active hone ka nishaan). */
class RainbowBorderView(context: Context) : View(context) {

    private val colors = intArrayOf(
        0xFFFF1744.toInt(), 0xFFFF9100.toInt(), 0xFFFFEA00.toInt(), 0xFF76FF03.toInt(),
        0xFF00E676.toInt(), 0xFF1DE9B6.toInt(), 0xFF00E5FF.toInt(), 0xFF2979FF.toInt(),
        0xFF651FFF.toInt(), 0xFFD500F9.toInt(), 0xFFFF2BD6.toInt(), 0xFFFF4081.toInt()
    )

    private val density = resources.displayMetrics.density
    private val stroke = 4f * density
    private val radius = 36f * density

    private val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = stroke
    }
    private val glow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = stroke * 2.5f
    }

    private val evaluator = ArgbEvaluator()
    private val path = Path()
    private val seg = Path()
    private var phase = 0f

    private val animator = ValueAnimator.ofFloat(0f, 1f).apply {
        duration = 6000
        repeatCount = ValueAnimator.INFINITE
        interpolator = LinearInterpolator()
        addUpdateListener {
            phase = it.animatedValue as Float
            invalidate()
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        animator.start()
    }

    override fun onDetachedFromWindow() {
        animator.cancel()
        super.onDetachedFromWindow()
    }

    private fun colorAt(x: Float): Int {
        var v = x % 1f
        if (v < 0f) v += 1f
        val f = v * colors.size
        val i = f.toInt()
        val c1 = colors[i % colors.size]
        val c2 = colors[(i + 1) % colors.size]
        return evaluator.evaluate(f - i, c1, c2) as Int
    }

    private fun drawSegments(
        canvas: Canvas, pm: PathMeasure, len: Float, n: Int, paint: Paint, alpha: Int
    ) {
        for (i in 0 until n) {
            seg.reset()
            val a = len * i / n
            val b = minOf(len, len * (i + 1) / n + 1f)
            pm.getSegment(a, b, seg, true)
            val c = colorAt(i.toFloat() / n - phase)
            paint.color = (c and 0x00FFFFFF) or (alpha shl 24)
            canvas.drawPath(seg, paint)
        }
    }

    override fun onDraw(canvas: Canvas) {
        val rect = RectF(stroke / 2, stroke / 2, width - stroke / 2, height - stroke / 2)
        path.reset()
        path.addRoundRect(rect, radius, radius, Path.Direction.CW)
        val pm = PathMeasure(path, false)
        val len = pm.length
        drawSegments(canvas, pm, len, 30, glow, 90)
        drawSegments(canvas, pm, len, 120, line, 255)
    }
}
