package com.asisgo.app.asisgo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val TAG = "AsisGoLive"
    private val CHANNEL = "com.asisgo.app/android_live_notification"
    private val NOTIFICATION_ID = 1001
    private val NOTIFICATION_CHANNEL_ID = "asisgo_dynamic_island_v3"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showLiveActivity" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args != null) {
                        showDynamicIslandNotification(args)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Argumentos nulos para Live Activity", null)
                    }
                }
                "cancelLiveActivity" -> {
                    cancelDynamicIslandNotification()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            try {
                notificationManager.deleteNotificationChannel("asisgo_shift_tracker")
                notificationManager.deleteNotificationChannel("asisgo_dynamic_island_v2")
            } catch (_: Exception) {}

            val name = "Dynamic Island (Turno en Vivo)"
            val descriptionText = "Notificación persistente con cronómetro y diseño idéntico a Dynamic Island"
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                name,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = descriptionText
                setShowBadge(true)
                enableVibration(false)
                setSound(null, null)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Canal de notificaciones $NOTIFICATION_CHANNEL_ID creado con éxito.")
        }
    }

    private fun showDynamicIslandNotification(args: Map<*, *>) {
        val phase = args["phase"] as? String ?: "working"
        val branchName = args["branchName"] as? String ?: "Sede Central"
        val shiftStartTimeMs = (args["shiftStartTime"] as? Number)?.toLong()
        val lunchStartTimeMs = (args["lunchStartTime"] as? Number)?.toLong()
        val isInsideGeozone = args["isInsideGeozone"] as? Boolean ?: true
        val punchesCount = (args["punchesCount"] as? Number)?.toInt() ?: 1

        Log.d(TAG, "showDynamicIslandNotification: phase=$phase, branch=$branchName, punches=$punchesCount, geozone=$isInsideGeozone")

        if (phase == "notStarted" || phase == "completed") {
            cancelDynamicIslandNotification()
            return
        }

        val isLunch = phase == "onLunch"
        val activeTimeMs = if (isLunch) lunchStartTimeMs else shiftStartTimeMs
        val nowMs = System.currentTimeMillis()
        val elapsedSinceEvent = if (activeTimeMs != null && activeTimeMs > 0) {
            Math.max(0L, nowMs - activeTimeMs)
        } else {
            0L
        }
        val chronometerBase = SystemClock.elapsedRealtime() - elapsedSinceEvent

        val timeFormatter = SimpleDateFormat("hh:mm a", Locale.getDefault())
        val formattedShiftTime = shiftStartTimeMs?.let { timeFormatter.format(Date(it)) } ?: "--:--"
        val formattedLunchTime = lunchStartTimeMs?.let { timeFormatter.format(Date(it)) } ?: "--:--"

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // RemoteViews Colapsada (Píldora ejecutiva y limpia, sin saturación)
        val collapsedView = RemoteViews(packageName, R.layout.notification_island_collapsed).apply {
            setTextViewText(R.id.island_branch_name, branchName)
            setChronometer(R.id.island_chronometer, chronometerBase, null, true)

            if (isLunch) {
                setTextViewText(R.id.island_status_badge, "EN REFRIGERIO")
                setInt(R.id.island_status_badge, "setBackgroundResource", R.drawable.bg_badge_subtle_amber)
                setTextColor(R.id.island_status_badge, android.graphics.Color.parseColor("#FBBF24"))
                setTextViewText(R.id.island_subtitle, "Pausa activa • $punchesCount de 4 marcas")
                setTextColor(R.id.island_chronometer, android.graphics.Color.parseColor("#FBBF24"))
            } else {
                val badgeText = if (phase == "resumed") "REANUDADO" else "EN TURNO"
                setTextViewText(R.id.island_status_badge, badgeText)
                setInt(R.id.island_status_badge, "setBackgroundResource", R.drawable.bg_badge_subtle_emerald)
                setTextColor(R.id.island_status_badge, android.graphics.Color.parseColor("#34D399"))
                val geoText = if (isInsideGeozone) "Dentro de geozona" else "Fuera de geozona"
                setTextViewText(R.id.island_subtitle, "$geoText • $punchesCount de 4 marcas")
                setTextColor(R.id.island_chronometer, android.graphics.Color.parseColor("#34D399"))
            }
        }

        // RemoteViews Expandida (Tarjeta ejecutiva y sobria)
        val expandedView = RemoteViews(packageName, R.layout.notification_island_expanded).apply {
            setTextViewText(R.id.island_branch_name_exp, branchName)
            setChronometer(R.id.island_chronometer_exp, chronometerBase, null, true)
            setTextViewText(R.id.island_progress_badge, "$punchesCount de 4 marcas")

            if (isInsideGeozone) {
                setTextViewText(R.id.island_geozone_badge, "Dentro de geozona")
                setTextColor(R.id.island_geozone_badge, android.graphics.Color.parseColor("#34D399"))
            } else {
                setTextViewText(R.id.island_geozone_badge, "Fuera de geozona")
                setTextColor(R.id.island_geozone_badge, android.graphics.Color.parseColor("#EF4444"))
            }

            if (isLunch) {
                setTextViewText(R.id.island_status_badge_exp, "EN REFRIGERIO")
                setInt(R.id.island_status_badge_exp, "setBackgroundResource", R.drawable.bg_badge_subtle_amber)
                setTextColor(R.id.island_status_badge_exp, android.graphics.Color.parseColor("#FBBF24"))
                setTextColor(R.id.island_chronometer_exp, android.graphics.Color.parseColor("#FBBF24"))
                setTextViewText(R.id.island_detail_text, "Pausa de refrigerio activa • Inicio: $formattedLunchTime (60 min)")
                setTextViewText(R.id.island_next_step, "Próxima marcación esperada: Finalizar Refrigerio")
            } else {
                val badgeText = if (phase == "resumed") "TURNO REANUDADO" else "EN TURNO"
                setTextViewText(R.id.island_status_badge_exp, badgeText)
                setInt(R.id.island_status_badge_exp, "setBackgroundResource", R.drawable.bg_badge_subtle_emerald)
                setTextColor(R.id.island_status_badge_exp, android.graphics.Color.parseColor("#34D399"))
                setTextColor(R.id.island_chronometer_exp, android.graphics.Color.parseColor("#FFFFFF"))

                if (phase == "resumed") {
                    setTextViewText(R.id.island_detail_text, "Segundo bloque de jornada • Ingreso: $formattedShiftTime")
                    setTextViewText(R.id.island_next_step, "Próxima marcación esperada: Marcar Salida")
                } else {
                    setTextViewText(R.id.island_detail_text, "Jornada laboral en curso • Ingreso: $formattedShiftTime")
                    setTextViewText(R.id.island_next_step, "Próxima marcación esperada: Iniciar Refrigerio")
                }
            }
        }

        val fallbackTitle = if (isLunch) "AsisGo • En Refrigerio" else "AsisGo • $branchName"
        val fallbackText = if (isLunch) "Pausa activa • $punchesCount de 4 marcas" else "En turno • $punchesCount de 4 marcas"

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(if (isLunch) R.drawable.ic_stat_refrigerio else R.drawable.ic_stat_shift)
            .setContentTitle(fallbackTitle)
            .setContentText(fallbackText)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .addAction(0, "Abrir AsisGo", pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val notificationManager = NotificationManagerCompat.from(this)
        try {
            notificationManager.notify(NOTIFICATION_ID, builder.build())
            Log.d(TAG, "Notificación Dynamic Island lanzada con éxito con ID $NOTIFICATION_ID")
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException al postear notificacion: ", e)
        } catch (e: Exception) {
            Log.e(TAG, "Exception general al postear notificacion: ", e)
        }
    }

    private fun cancelDynamicIslandNotification() {
        val notificationManager = NotificationManagerCompat.from(this)
        notificationManager.cancel(NOTIFICATION_ID)
        Log.d(TAG, "Notificación cancelada.")
    }
}
