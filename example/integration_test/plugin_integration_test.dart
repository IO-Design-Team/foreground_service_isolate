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
  id: 1,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
);
const notificationDetailsNoTap = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  id: 2,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
  tapAction: NotificationTapAction.none,
);
const notificationDetailsDeepLink = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  id: 3,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
  tapAction: NotificationTapAction.launchDeepLink,
  tapDeepLink: 'foreground-service-isolate://session/1',
);
const notificationDetailsIntentAction = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  id: 4,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
  tapAction: NotificationTapAction.launchIntentAction,
  tapIntentAction: 'com.iodesignteam.foreground_service_isolate_example.OPEN',
);
const notificationDetailsLaunchApp = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  id: 5,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
  tapAction: NotificationTapAction.launchApp,
);
const notificationDetailsDismissible = NotificationDetails(
  channelId: 'foreground_service_isolate',
  channelName: 'Foreground Service Isolate',
  id: 6,
  contentTitle: 'Foreground Service Isolate',
  contentText: 'Running...',
  smallIcon: 'ic_launcher',
  dismissible: true,
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

  test('tapAction none does not crash service startup', () async {
    await spawnAndPing(notificationDetailsNoTap);
  });

  test('tapAction deepLink does not crash service startup', () async {
    await spawnAndPing(notificationDetailsDeepLink);
  });

  test('tapAction intentAction does not crash service startup', () async {
    await spawnAndPing(notificationDetailsIntentAction);
  });

  test('tapAction launchApp does not crash service startup', () async {
    await spawnAndPing(notificationDetailsLaunchApp);
  });

  test('dismissible notification does not crash service startup', () async {
    await spawnAndPing(notificationDetailsDismissible);
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

Future<void> spawnAndPing(NotificationDetails details) async {
  final connection = await spawnForegroundServiceIsolate(
    entryPoint,
    notificationDetails: details,
  );

  try {
    final methodChannel = IsolateMethodChannel(methodChannelId, connection);
    final result = await methodChannel.invokeMethod('ping');
    expect(result, 'pong');
  } finally {
    connection.close();
  }
}
