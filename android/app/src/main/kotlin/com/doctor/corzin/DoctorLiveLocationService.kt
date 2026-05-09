package com.doctor.corzin

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.atomic.AtomicBoolean

class DoctorLiveLocationService : Service(), LocationListener {
    private val handler = Handler(Looper.getMainLooper())
    private var locationManager: LocationManager? = null
    private var lastLocation: Location? = null
    private var doctorId: Int = 0
    private var baseUrl: String = ""
    private val uploadInProgress = AtomicBoolean(false)

    private val uploadRunnable = object : Runnable {
        override fun run() {
            lastLocation?.let { uploadLocation(it) }
            handler.postDelayed(this, SYNC_INTERVAL_MS)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            saveTrackingState(active = false)
            stopTracking()
            return START_NOT_STICKY
        }

        val saved = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        if (intent == null && !saved.getBoolean(KEY_ACTIVE, false)) {
            stopSelf()
            return START_NOT_STICKY
        }

        doctorId = intent?.getIntExtra(EXTRA_DOCTOR_ID, 0)?.takeIf { it > 0 }
            ?: saved.getInt(KEY_DOCTOR_ID, 0)
        baseUrl = intent?.getStringExtra(EXTRA_BASE_URL)?.takeIf { it.isNotBlank() }
            ?: saved.getString(KEY_BASE_URL, "").orEmpty()

        if (doctorId <= 0 || baseUrl.isBlank() || !hasRequiredLocationPermissions()) {
            stopSelf()
            return START_NOT_STICKY
        }

        saveTrackingState(active = true)

        if (!startForegroundSafely()) {
            stopSelf()
            return START_NOT_STICKY
        }

        startLocationUpdates()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopLocationUpdates()
        super.onDestroy()
    }

    override fun onLocationChanged(location: Location) {
        lastLocation = location
        uploadLocation(location)
    }

    @Deprecated("Required for older Android LocationListener callbacks.")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        // No-op. Android 9 and older can still call this callback.
    }

    override fun onProviderEnabled(provider: String) {
        // No-op. Keeping this implemented avoids legacy runtime callback crashes.
    }

    override fun onProviderDisabled(provider: String) {
        // No-op. Keeping this implemented avoids legacy runtime callback crashes.
    }

    private fun startForegroundSafely(): Boolean {
        return try {
            createNotificationChannel()
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun startLocationUpdates() {
        if (!hasRequiredLocationPermissions()) return

        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val manager = locationManager ?: return
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)

        for (provider in providers) {
            try {
                if (manager.isProviderEnabled(provider)) {
                    manager.requestLocationUpdates(
                        provider,
                        SYNC_INTERVAL_MS,
                        0f,
                        this,
                        Looper.getMainLooper(),
                    )
                    manager.getLastKnownLocation(provider)?.let { candidate ->
                        val current = lastLocation
                        if (current == null || candidate.time > current.time) {
                            lastLocation = candidate
                        }
                    }
                }
            } catch (_: Throwable) {}
        }

        lastLocation?.let { uploadLocation(it) }
        handler.removeCallbacks(uploadRunnable)
        handler.postDelayed(uploadRunnable, SYNC_INTERVAL_MS)
    }

    private fun stopTracking() {
        stopLocationUpdates()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun stopLocationUpdates() {
        handler.removeCallbacks(uploadRunnable)
        try {
            locationManager?.removeUpdates(this)
        } catch (_: Throwable) {}
        locationManager = null
    }

    private fun uploadLocation(location: Location) {
        if (doctorId <= 0 || baseUrl.isBlank()) return
        if (!uploadInProgress.compareAndSet(false, true)) return

        Thread {
            try {
                val url = URL("${baseUrl.trimEnd('/')}/doctor/live-location/$doctorId")
                val body = "latitude=${encode(location.latitude.toString())}&longitude=${encode(location.longitude.toString())}"
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 15000
                    readTimeout = 15000
                    doOutput = true
                    setRequestProperty("Accept", "application/json")
                    setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
                }

                OutputStreamWriter(connection.outputStream).use { writer ->
                    writer.write(body)
                    writer.flush()
                }

                try {
                    if (connection.responseCode in 200..299) {
                        connection.inputStream.close()
                    } else {
                        connection.errorStream?.close()
                    }
                } finally {
                    connection.disconnect()
                }
            } catch (_: Throwable) {
            } finally {
                uploadInProgress.set(false)
            }
        }.start()
    }

    private fun hasRequiredLocationPermissions(): Boolean {
        val fine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (!fine && !coarse) return false

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            hasPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        } else {
            true
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Doctor live location",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps doctor live location updated while active."
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Corvet live location")
            .setContentText("Doctor live location tracking is active.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    private fun saveTrackingState(active: Boolean) {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ACTIVE, active)
            .putInt(KEY_DOCTOR_ID, doctorId)
            .putString(KEY_BASE_URL, baseUrl)
            .apply()
    }

    private fun encode(value: String): String = URLEncoder.encode(value, "UTF-8")

    companion object {
        const val ACTION_START = "com.doctor.corzin.action.START_LIVE_LOCATION"
        const val ACTION_STOP = "com.doctor.corzin.action.STOP_LIVE_LOCATION"
        const val EXTRA_DOCTOR_ID = "doctor_id"
        const val EXTRA_BASE_URL = "base_url"

        private const val PREFS_NAME = "doctor_live_location_service"
        private const val KEY_ACTIVE = "active"
        private const val KEY_DOCTOR_ID = "doctor_id"
        private const val KEY_BASE_URL = "base_url"
        private const val CHANNEL_ID = "doctor_live_location_native"
        private const val NOTIFICATION_ID = 14031
        private const val SYNC_INTERVAL_MS = 60_000L
    }
}
