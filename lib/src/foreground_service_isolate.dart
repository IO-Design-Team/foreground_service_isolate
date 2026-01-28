import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isolate_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

/// Wrapper for the foreground service isolate methods
class ForegroundServiceIsolate {
  static const _methodChannel = MethodChannel('foreground_service_isolate');

  /// Spawn an isolate in a foreground service
  static Future<ForegroundServiceIsolate> spawn(
    IsolateEntryPoint entryPoint,
    SendPort send, {
    bool paused = false,
    bool errorsAreFatal = true,
    SendPort? onExit,
    SendPort? onError,
    String? debugName,
    required String notificationChannelId,
    required int notificationId,
  }) async {
    final isolateId = const Uuid().v4();
    IsolateNameServer.registerPortWithName(send, isolateId);

    final spawnFuture = _methodChannel.invokeMethod('spawn', {
      'notificationChannelId': notificationChannelId,
      'notificationId': notificationId,
      'entryPoint':
          PluginUtilities.getCallbackHandle(foregroundServiceIsolateEntryPoint)
              ?.toRawHandle(),
      'userEntryPoint':
          PluginUtilities.getCallbackHandle(entryPoint)?.toRawHandle(),
      'isolateId': isolateId,
    });
    unawaited(spawnFuture);

    return ForegroundServiceIsolate();
  }
}

/// Entry point for the foreground service isolate
@pragma('vm:entry-point')
void foregroundServiceIsolateEntryPoint(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  final isolateId = args[0];
  final send = IsolateNameServer.lookupPortByName(isolateId);
  if (send == null) throw StateError('SendPort not registered');

  final userEntryPointHandle = int.parse(args[1]);
  final userEntryPoint = PluginUtilities.getCallbackFromHandle(
    CallbackHandle.fromRawHandle(userEntryPointHandle),
  );

  if (userEntryPoint == null) throw StateError('User entry point not found');

  userEntryPoint(send);
}
