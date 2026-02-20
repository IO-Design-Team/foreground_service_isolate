import 'dart:async';
import 'dart:isolate';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

const notificationDetails = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  channelDescription: 'Foreground Service Isolate',
  id: 1,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
);
const methodChannelId = 'method_channel';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  tearDown(() async {
    await ForegroundServiceIsolate.stopService();
    await Future.delayed(const Duration(seconds: 1));
  });

  test('Foreground service notification is created', () async {
    final flnp = FlutterLocalNotificationsPlugin();

    final an1 = await flnp.getActiveNotifications();
    expect(an1, isEmpty);

    final connection = await spawnForegroundServiceIsolate(
      entryPoint,
      notificationDetails: notificationDetails,
    );

    // https://developer.android.com/about/versions/12/behavior-changes-all#foreground-service-notification-delay
    await Future.delayed(const Duration(seconds: 10));

    final an2 = await flnp.getActiveNotifications();
    expect(an2, hasLength(1));

    connection.close();

    final an3 = await flnp.getActiveNotifications();
    expect(an3, isEmpty);
  });

  test('ping/pong', () async {
    final connection = await spawnForegroundServiceIsolate(
      entryPoint,
      notificationDetails: notificationDetails,
    );

    final methodChannel = IsolateMethodChannel(methodChannelId, connection);
    final result = await methodChannel.invokeMethod('ping');
    expect(result, 'pong');
  });

  test('onExit called', () async {
    final onExitCompleter = Completer<void>();
    await spawnForegroundServiceIsolate(
      entryPoint,
      onExit: onExitCompleter.complete,
      notificationDetails: notificationDetails,
    );
    await ForegroundServiceIsolate.stopService();

    expect(onExitCompleter.future, completes);
  });

  test('onError called', () async {
    final onErrorCompleter = Completer<void>();
    await spawnForegroundServiceIsolate(
      errorEntryPoint,
      onError: (_, _) => onErrorCompleter.complete(),
      notificationDetails: notificationDetails,
    );

    expect(onErrorCompleter.future, completes);
  });
}

@pragma('vm:entry-point')
void entryPoint(SendPort? send) {
  final connection = setupIsolate(send);
  final methodChannel = IsolateMethodChannel(methodChannelId, connection);

  methodChannel.setMethodCallHandler(
    (call) => switch (call.method) {
      'ping' => 'pong',
      _ => call.notImplemented(),
    },
  );
}

@pragma('vm:entry-point')
void errorEntryPoint(SendPort? send) {
  setupIsolate(send);
  throw Exception();
}
