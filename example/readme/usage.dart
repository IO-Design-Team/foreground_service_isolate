import 'dart:isolate';

import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

void example() async {
  // Notification permission is required to show a foreground service notification
  await Permission.notification.request();

  final connection = await spawnForegroundServiceIsolate(
    isolateEntryPoint,
    notificationDetails: const NotificationDetails(
      channelId: 'foreground_service_isolate',
      channelName: 'Foreground Service Isolate',
      id: 1,
      contentTitle: 'Foreground Service Isolate',
      contentText: 'Running...',
      // This resource must be present in android/app/src/main/res/drawable
      smallIcon: 'ic_launcher',
    ),
  );
}

@pragma('vm:entry-point')
void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);
}
