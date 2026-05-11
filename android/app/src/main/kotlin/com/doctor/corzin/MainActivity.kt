package com.doctor.corzin

import android.content.Intent
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val toneChannelName = "doctor_corzin/alert_tone"
    private val locationChannelName = "doctor_corzin/live_location_service"

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
                    "clearNotifications" -> {
                        clearNotifications()
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
        return DoctorAlertToneService.start(this)
    }

    private fun stopUniqueTone() {
        DoctorAlertToneService.stop(this)
    }

    private fun clearNotifications() {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancelAll()
        } catch (_: Throwable) {
        }
    }
}
