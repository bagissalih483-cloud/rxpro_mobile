package com.fix.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelId = "rxpro_high_importance"
    private val methodChannelName = "rxpro/native_notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createFixNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "showNotification") {
                val notificationId = call.argument<String>("notificationId") ?: ""
                val title = call.argument<String>("title") ?: "fix"
                val body = call.argument<String>("body") ?: "Yeni bildiriminiz var."
                val type = call.argument<String>("type") ?: ""
                val route = call.argument<String>("route") ?: ""
                val businessId = call.argument<String>("businessId") ?: ""
                val businessName = call.argument<String>("businessName") ?: ""
                val appointmentId = call.argument<String>("appointmentId") ?: ""
                val targetScope = call.argument<String>("targetScope") ?: ""
                val recipientUid = call.argument<String>("recipientUid") ?: ""

                showFixNotification(
                    notificationId = notificationId,
                    title = title,
                    body = body,
                    type = type,
                    route = route,
                    businessId = businessId,
                    businessName = businessName,
                    appointmentId = appointmentId,
                    targetScope = targetScope,
                    recipientUid = recipientUid
                )

                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createFixNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "fix Bildirimleri"
            val descriptionText = "Randevu, erteleme, iptal ve kampanya bildirimleri"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = descriptionText
                enableVibration(true)
                enableLights(true)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showFixNotification(
        notificationId: String,
        title: String,
        body: String,
        type: String,
        route: String,
        businessId: String,
        businessName: String,
        appointmentId: String,
        targetScope: String,
        recipientUid: String
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "FLUTTER_NOTIFICATION_CLICK"
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notificationId", notificationId)
            putExtra("type", type)
            putExtra("route", route)
            putExtra("businessId", businessId)
            putExtra("businessName", businessName)
            putExtra("appointmentId", appointmentId)
            putExtra("targetScope", targetScope)
            putExtra("recipientUid", recipientUid)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            pendingIntentFlags
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, channelId)
        } else {
            android.app.Notification.Builder(this)
        }

        val notification = builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(android.app.Notification.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setShowWhen(true)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
