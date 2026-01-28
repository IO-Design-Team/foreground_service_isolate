import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

const eventChannelId = 'foreground_service_isolate_event';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  final connection = await spawnForegroundServiceIsolate(
    isolateEntryPoint,
    notificationChannelId: 'foreground_service_isolate',
    notificationId: 1,
  );

  final eventChannel = IsolateEventChannel(eventChannelId, connection);
  eventChannel.receiveBroadcastStream().listen(print);
}

@pragma('vm:entry-point')
void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final eventChannel = IsolateEventChannel(eventChannelId, connection);
  eventChannel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (_, sink) async {
        while (true) {
          sink.success('Hello from the isolate');
          await Future.delayed(const Duration(seconds: 1));
        }
      },
    ),
  );
}
