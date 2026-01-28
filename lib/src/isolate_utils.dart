import 'dart:isolate';

import 'package:foreground_service_isolate/foreground_service_isolate.dart';

/// Spawn an isolate in a foreground service
Future<IsolateConnection> spawnForegroundServiceIsolate(
  IsolateEntryPoint entryPoint, {
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  required NotificationDetails notificationDetails,
}) {
  return spawnIsolateConnection(
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    spawn: (send, control) => ForegroundServiceIsolate.spawn(
      entryPoint,
      send,
      onExit: control,
      onError: control,
      notificationDetails: notificationDetails,
    ),
  );
}
