package com.iodesignteam.foreground_service_isolate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat.startForegroundService
import com.google.gson.Gson
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.FlutterCallbackInformation

/** ForegroundServiceIsolatePlugin */
class ForegroundServiceIsolatePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger, "foreground_service_isolate"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall, result: Result
    ) {
        when (call.method) {
            "spawn" -> spawn(call, result)
            "stopService" -> stopService(result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun spawn(call: MethodCall, result: Result) {
        val notificationDetailsJson = call.argument<String>("notificationDetails")
        val notificationDetails =
            Gson().fromJson(notificationDetailsJson, NotificationDetails::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationDetails.channelId,
                notificationDetails.channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        val intent = Intent(context, IsolateForegroundService::class.java)
        intent.putExtra("notificationDetails", notificationDetailsJson)
        intent.putExtra("foregroundServiceType", call.argument<Int>("foregroundServiceType"))
        intent.putExtra("entryPoint", call.argument<Long>("entryPoint"))
        intent.putExtra("userEntryPoint", call.argument<Long>("userEntryPoint"))
        intent.putExtra("isolateId", call.argument<String>("isolateId"))
        startForegroundService(context, intent)
        result.success(null)
    }

    private fun stopService(result: Result) {
        val intent = Intent(context, IsolateForegroundService::class.java)
        context.stopService(intent)
        result.success(null)
    }
}

class IsolateForegroundService : Service() {
    companion object {
        var flutterEngineGroup: FlutterEngineGroup? = null
    }

    var flutterEngine: FlutterEngine? = null

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        if (flutterEngine != null) return START_REDELIVER_INTENT

        val notificationDetailsJson = intent.getStringExtra("notificationDetails")!!
        val notificationDetails =
            Gson().fromJson(notificationDetailsJson, NotificationDetails::class.java)

        val foregroundServiceType = intent.getIntExtra("foregroundServiceType", -1)
        val entryPoint = intent.getLongExtra("entryPoint", -1)
        val userEntryPoint = intent.getLongExtra("userEntryPoint", -1)
        val isolateId = intent.getStringExtra("isolateId")!!

        val smallIcon = resources.getIdentifier(
            notificationDetails.smallIcon,
            "drawable",
            applicationContext.packageName,
        )

        if (smallIcon == 0) {
            throw IllegalArgumentException("Small icon not found: ${notificationDetails.smallIcon}")
        }

        val notification = NotificationCompat.Builder(this, notificationDetails.channelId)
            .setContentTitle(notificationDetails.contentTitle)
            .setContentText(notificationDetails.contentText).setSmallIcon(smallIcon).build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationDetails.id, notification, foregroundServiceType)
        } else {
            startForeground(notificationDetails.id, notification)
        }

        FlutterInjector.instance().flutterLoader().ensureInitializationComplete(this, null)
        val flutterCallbackInformation =
            FlutterCallbackInformation.lookupCallbackInformation(entryPoint)

        flutterEngineGroup = flutterEngineGroup ?: FlutterEngineGroup(this)

        val engineOptions = FlutterEngineGroup.Options(this)
        engineOptions.dartEntrypoint = DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            flutterCallbackInformation.callbackLibraryPath,
            flutterCallbackInformation.callbackName
        )
        engineOptions.dartEntrypointArgs = listOf(isolateId, userEntryPoint.toString())

        flutterEngine = flutterEngineGroup!!.createAndRunEngine(engineOptions)

        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        flutterEngine?.destroy()
        flutterEngine = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

class NotificationDetails(
    val channelId: String,
    val channelName: String,
    val id: Int,
    val contentTitle: String,
    val contentText: String,
    val smallIcon: String
)