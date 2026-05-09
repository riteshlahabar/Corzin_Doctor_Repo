package com.doctor.corzin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import kotlin.math.PI
import kotlin.math.sin

class DoctorAlertToneService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var audioTrack: AudioTrack? = null
    private var vibrator: Vibrator? = null
    private val stopRunnable = Runnable { stopToneAndSelf() }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopToneAndSelf()
            return START_NOT_STICKY
        }

        if (!startForegroundSafely()) {
            stopToneAndSelf()
            return START_NOT_STICKY
        }

        startGeneratedTone()
        startVibration()
        handler.removeCallbacks(stopRunnable)
        handler.postDelayed(stopRunnable, DURATION_MS)
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopTone()
        super.onDestroy()
    }

    private fun startGeneratedTone() {
        if (audioTrack != null) return

        val sampleRate = 44100
        val samples = buildTonePattern(sampleRate)
        val track = createAudioTrack(sampleRate, samples.size * 2) ?: return
        audioTrack = track

        try {
            track.write(samples, 0, samples.size)
            track.setLoopPoints(0, samples.size, -1)
            track.play()
        } catch (_: Throwable) {
            stopTone()
        }
    }

    private fun createAudioTrack(sampleRate: Int, bufferSizeInBytes: Int): AudioTrack? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val format = AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
                AudioTrack.Builder()
                    .setAudioAttributes(attributes)
                    .setAudioFormat(format)
                    .setBufferSizeInBytes(bufferSizeInBytes)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_ALARM,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSizeInBytes,
                    AudioTrack.MODE_STATIC,
                )
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun buildTonePattern(sampleRate: Int): ShortArray {
        val durationMs = 1100
        val samples = ShortArray(sampleRate * durationMs / 1000)

        fun addTone(startMs: Int, lengthMs: Int, frequency: Double) {
            val start = sampleRate * startMs / 1000
            val length = sampleRate * lengthMs / 1000
            val end = minOf(samples.size, start + length)
            val attack = maxOf(1, sampleRate * 10 / 1000)
            val release = maxOf(1, sampleRate * 16 / 1000)

            for (index in start until end) {
                val offset = index - start
                val remaining = end - index
                val attackFactor = minOf(1.0, offset.toDouble() / attack)
                val releaseFactor = minOf(1.0, remaining.toDouble() / release)
                val envelope = minOf(attackFactor, releaseFactor)
                val angle = 2.0 * PI * frequency * offset / sampleRate
                samples[index] = (sin(angle) * Short.MAX_VALUE * 0.58 * envelope).toInt().toShort()
            }
        }

        addTone(startMs = 0, lengthMs = 140, frequency = 980.0)
        addTone(startMs = 190, lengthMs = 140, frequency = 720.0)
        addTone(startMs = 390, lengthMs = 180, frequency = 1180.0)
        return samples
    }

    private fun startForegroundSafely(): Boolean {
        return try {
            createNotificationChannel()
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Doctor appointment alert",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Plays the doctor appointment alert tone."
            setSound(null, null)
            enableVibration(false)
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
                .setPriority(Notification.PRIORITY_LOW)
                .setSound(null)
                .setVibrate(longArrayOf(0L))
        }

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Appointment alert")
            .setContentText("New appointment request ringing.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_ALARM)
            .build()
    }

    private fun stopToneAndSelf() {
        stopTone()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun stopTone() {
        handler.removeCallbacks(stopRunnable)
        stopVibration()
        audioTrack?.let { track ->
            try {
                track.pause()
                track.flush()
                track.stop()
            } catch (_: Throwable) {
            } finally {
                try {
                    track.release()
                } catch (_: Throwable) {}
            }
        }
        audioTrack = null
    }

    private fun startVibration() {
        vibrator = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
        } catch (_: Throwable) {
            null
        }

        val pattern = longArrayOf(0L, 600L, 320L)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Throwable) {}
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (_: Throwable) {
        } finally {
            vibrator = null
        }
    }

    companion object {
        const val ACTION_START = "com.doctor.corzin.action.START_ALERT_TONE"
        const val ACTION_STOP = "com.doctor.corzin.action.STOP_ALERT_TONE"

        private const val CHANNEL_ID = "doctor_appointment_alert_tone"
        private const val NOTIFICATION_ID = 14032
        private const val DURATION_MS = 20_000L

        fun start(context: Context): Boolean {
            return try {
                val intent = Intent(context, DoctorAlertToneService::class.java).apply {
                    action = ACTION_START
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (_: Throwable) {
                false
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, DoctorAlertToneService::class.java))
            } catch (_: Throwable) {}
        }
    }
}
