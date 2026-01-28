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
            "kill" -> kill(result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun spawn(call: MethodCall, result: Result) {
        val intent = Intent(context, IsolateForegroundService::class.java)
        intent.putExtra("notificationChannelId", call.argument<String>("notificationChannelId"))
        intent.putExtra("notificationId", call.argument<Int>("notificationId"))
        intent.putExtra("entryPoint", call.argument<Long>("entryPoint"))
        intent.putExtra("userEntryPoint", call.argument<Long>("userEntryPoint"))
        intent.putExtra("isolateId", call.argument<String>("isolateId"))
        startForegroundService(context, intent)
        result.success(null)
    }

    private fun kill(result: Result) {
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
        if (flutterEngine != null) return START_NOT_STICKY

        val notificationChannelId = intent.getStringExtra("notificationChannelId")!!
        val notificationId = intent.getIntExtra("notificationId", -1)
        val entryPoint = intent.getLongExtra("entryPoint", -1)
        val userEntryPoint = intent.getLongExtra("userEntryPoint", -1)
        val isolateId = intent.getStringExtra("isolateId")!!

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId, "Foreground Service", NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle("Foreground Service").setContentText("Running...")
            .setSmallIcon(android.R.drawable.ic_dialog_info).build()

        startForeground(notificationId, notification)

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

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        flutterEngine?.destroy()
        flutterEngine = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}