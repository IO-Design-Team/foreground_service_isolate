import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationDetails;
import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

const methodChannelId = 'foreground_service_isolate_method';
const notificationId = 1;

void example() async {
  // Notification permission is required to show a foreground service notification
  await Permission.notification.request();

  // The tap intent matches flutter_local_notifications, so that plugin reports
  // taps on this notification.
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (details) {
      if (details.id == notificationId) {
        debugPrint('Tapped foreground service notification');
      }
    },
  );

  final launchDetails = await notifications.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true &&
      launchDetails?.notificationResponse?.id == notificationId) {
    debugPrint('Launched from foreground service notification');
  }

  final connection = await spawnForegroundServiceIsolate(
    isolateEntryPoint,
    notificationDetails: const NotificationDetails(
      channelId: 'foreground_service_isolate',
      channelName: 'Foreground Service Isolate',
      id: notificationId,
      contentTitle: 'Foreground Service Isolate',
      contentText: 'Running...',
      // This resource must be present in android/app/src/main/res/drawable
      smallIcon: 'ic_launcher',
    ),
  );

  final methodChannel = IsolateMethodChannel(methodChannelId, connection);
  final result = await methodChannel.invokeMethod('ping');
  debugPrint(result);
}

@pragma('vm:entry-point')
void isolateEntryPoint(SendPort? send) {
  final connection = setupIsolate(send);

  final methodChannel = IsolateMethodChannel(methodChannelId, connection);
  methodChannel.setMethodCallHandler(
    (call) => switch (call.method) {
      'ping' => 'pong',
      _ => call.notImplemented(),
    },
  );
}
