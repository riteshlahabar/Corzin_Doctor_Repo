package com.doctor.corzin

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val toneChannelName = "doctor_corzin/alert_tone"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var toneGenerator: ToneGenerator? = null
    private var toneRunnable: Runnable? = null
    private var toneRunning = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, toneChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startUniqueTone" -> {
                        startUniqueTone()
                        result.success(true)
                    }
                    "stopUniqueTone" -> {
                        stopUniqueTone()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startUniqueTone() {
        if (toneRunning) return
        toneRunning = true
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        } catch (_: Throwable) {
            toneRunning = false
            return
        }

        toneRunnable = object : Runnable {
            override fun run() {
                if (!toneRunning) return
                playUniquePattern()
                mainHandler.postDelayed(this, 1100)
            }
        }
        toneRunnable?.let { mainHandler.post(it) }
    }

    private fun playUniquePattern() {
        val tg = toneGenerator ?: return
        tg.startTone(ToneGenerator.TONE_DTMF_9, 120)
        mainHandler.postDelayed({ if (toneRunning) tg.startTone(ToneGenerator.TONE_DTMF_7, 120) }, 180)
        mainHandler.postDelayed({ if (toneRunning) tg.startTone(ToneGenerator.TONE_DTMF_9, 160) }, 360)
    }

    private fun stopUniqueTone() {
        toneRunning = false
        toneRunnable?.let { mainHandler.removeCallbacks(it) }
        toneRunnable = null
        toneGenerator?.stopTone()
        toneGenerator?.release()
        toneGenerator = null
    }

    override fun onDestroy() {
        stopUniqueTone()
        super.onDestroy()
    }
}
