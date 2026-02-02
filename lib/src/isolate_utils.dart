import 'package:foreground_service_isolate/foreground_service_isolate.dart';

/// Spawn an isolate in a foreground service
Future<IsolateConnection> spawnForegroundServiceIsolate(
  IsolateEntryPoint entryPoint, {
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  required NotificationDetails notificationDetails,
  Set<ForegroundServiceType> foregroundServiceTypes = const {},
}) async {
  final connection = await spawnIsolateConnection(
    onExit: onExit,
    onError: onError,
    spawn: (send) => ForegroundServiceIsolate.spawn(
      entryPoint,
      send,
      notificationDetails: notificationDetails,
      foregroundServiceTypes: foregroundServiceTypes,
    ),
  );

  return connection;
}
