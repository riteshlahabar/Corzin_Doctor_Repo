package com.doctor.corzin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

class DoctorFirebaseMessagingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        val data = mutableMapOf<String, String>()
        for (key in extras.keySet()) {
            val value = extras.get(key)?.toString()?.takeIf { it.isNotBlank() } ?: continue
            data[key] = value
        }
        val title = firstNotBlank(
            data["title"],
            data["gcm.notification.title"],
            data["event"],
            "",
        )
        val body = firstNotBlank(
            data["body"],
            data["message"],
            data["gcm.notification.body"],
            "",
        )

        if (isAppointmentClosedByOtherDoctor(title, body, data)) {
            DoctorAlertToneService.stop(context)
            return
        }

        if (shouldPlayForMessage(context, title, body, data)) {
            DoctorAlertToneService.start(context)
        }
    }

    private fun shouldPlayForMessage(
        context: Context,
        title: String,
        body: String,
        data: Map<String, String>,
    ): Boolean {
        if (!isNewAppointmentRequest(title, body, data)) return false

        val payloadDoctorId = data["doctor_id"]?.trim()?.toIntOrNull()
        if (payloadDoctorId == null || payloadDoctorId <= 0) return true

        val activeDoctorId = readLoggedInDoctorId(context)
        return activeDoctorId != null && activeDoctorId > 0 && activeDoctorId == payloadDoctorId
    }

    private fun isNewAppointmentRequest(
        title: String,
        body: String,
        data: Map<String, String>,
    ): Boolean {
        val type = data["type"].orEmpty().lowercase()
        val event = data["event"].orEmpty().lowercase()
        val status = data["status"].orEmpty().lowercase()
        val subject = "$title $body".lowercase()

        return event == "appointment_created" ||
            (type == "doctor_appointment" &&
                status == "pending" &&
                subject.contains("new appointment request"))
    }

    private fun isAppointmentClosedByOtherDoctor(
        title: String,
        body: String,
        data: Map<String, String>,
    ): Boolean {
        val event = data["event"].orEmpty().lowercase()
        val status = data["status"].orEmpty().lowercase()
        val subject = "$title $body".lowercase()

        return event == "appointment_taken_by_other_doctor" ||
            event == "appointment_closed" ||
            status == "closed_by_other_doctor" ||
            subject.contains("accepted by another doctor") ||
            subject.contains("accepted by another nearby doctor") ||
            (subject.contains("another doctor") && subject.contains("accepted"))
    }

    private fun readLoggedInDoctorId(context: Context): Int? {
        return try {
            val raw = context
                .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.doctor_profile", null)
                ?.takeIf { it.isNotBlank() }
                ?: return null
            JSONObject(raw).optInt("id").takeIf { it > 0 }
        } catch (_: Throwable) {
            null
        }
    }

    private fun firstNotBlank(vararg values: String?): String {
        return values.firstOrNull { !it.isNullOrBlank() }?.trim().orEmpty()
    }
}
