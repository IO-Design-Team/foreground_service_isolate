// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'dart:isolate';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  test('Foreground service notification is created', () async {
    final flnp = FlutterLocalNotificationsPlugin();

    final an1 = await flnp.getActiveNotifications();
    expect(an1, isEmpty);

    final connection = await spawnForegroundServiceIsolate(
      entryPoint,
      notificationDetails: const NotificationDetails(
        channelId: 'foreground_service_isolate',
        channelName: 'Foreground Service Isolate',
        id: 1,
        contentTitle: 'Foreground Service Isolate',
        contentText: 'Running...',
      ),
    );

    // https://developer.android.com/about/versions/12/behavior-changes-all#foreground-service-notification-delay
    await Future.delayed(const Duration(seconds: 10));

    final an2 = await flnp.getActiveNotifications();
    expect(an2, hasLength(1));

    connection.close();

    final an3 = await flnp.getActiveNotifications();
    expect(an3, isEmpty);
  });
}

@pragma('vm:entry-point')
void entryPoint(SendPort send) {
  setupIsolate(send);
}
