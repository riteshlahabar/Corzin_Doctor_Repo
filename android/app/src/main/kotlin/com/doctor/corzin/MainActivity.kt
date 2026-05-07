package com.doctor.corzin

import android.content.Intent
import android.os.Build
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val toneChannelName = "doctor_corzin/alert_tone"
    private val locationChannelName = "doctor_corzin/live_location_service"
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
                        result.success(startUniqueTone())
                    }
                    "stopUniqueTone" -> {
                        stopUniqueTone()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val args = call.arguments as? Map<*, *>
                        val doctorId = (args?.get("doctorId") as? Number)?.toInt() ?: 0
                        val baseUrl = args?.get("baseUrl")?.toString().orEmpty()
                        result.success(startLiveLocationService(doctorId, baseUrl))
                    }
                    "stop" -> {
                        stopLiveLocationService()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startLiveLocationService(doctorId: Int, baseUrl: String): Boolean {
        if (doctorId <= 0 || baseUrl.isBlank()) return false

        return try {
            val intent = Intent(this, DoctorLiveLocationService::class.java).apply {
                action = DoctorLiveLocationService.ACTION_START
                putExtra(DoctorLiveLocationService.EXTRA_DOCTOR_ID, doctorId)
                putExtra(DoctorLiveLocationService.EXTRA_BASE_URL, baseUrl)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun stopLiveLocationService() {
        try {
            val intent = Intent(this, DoctorLiveLocationService::class.java).apply {
                action = DoctorLiveLocationService.ACTION_STOP
            }
            startService(intent)
        } catch (_: Throwable) {
            stopService(Intent(this, DoctorLiveLocationService::class.java))
        }
    }

    private fun startUniqueTone(): Boolean {
        if (toneRunning) return true
        toneRunning = true
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        } catch (_: Throwable) {
            toneRunning = false
            return false
        }

        toneRunnable = object : Runnable {
            override fun run() {
                if (!toneRunning) return
                playUniquePattern()
                mainHandler.postDelayed(this, 1100)
            }
        }
        toneRunnable?.let { mainHandler.post(it) }
        return true
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
