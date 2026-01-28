import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:foreground_service_isolate/foreground_service_isolate.dart';

Future<IsolateConnection> spawnForegroundServiceIsolate(
  IsolateEntryPoint entryPoint, {
  bool paused = false,
  bool errorsAreFatal = true,
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  String? debugName,
}) {
  return spawnIsolate(
    entryPoint,
    paused: paused,
    errorsAreFatal: errorsAreFatal,
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    debugName: debugName,
    spawn: (send, control) => ForegroundServiceIsolate.spawn(entryPoint),
  );
}
