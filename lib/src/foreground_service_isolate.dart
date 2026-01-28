import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isolate_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

String _sendName(String isolateId) => '$isolateId/send';
String _onExitName(String isolateId) => '$isolateId/onExit';
String _onErrorName(String isolateId) => '$isolateId/onError';

/// Wrapper for the foreground service isolate methods
class ForegroundServiceIsolate {
  static const _methodChannel = MethodChannel('foreground_service_isolate');

  /// Spawn an isolate in a foreground service
  static Future<ForegroundServiceIsolate> spawn(
    IsolateEntryPoint entryPoint,
    SendPort send, {
    SendPort? onExit,
    SendPort? onError,
    required String notificationChannelId,
    required int notificationId,
  }) async {
    final isolateId = const Uuid().v4();
    IsolateNameServer.registerPortWithName(send, _sendName(isolateId));
    if (onExit != null) {
      IsolateNameServer.registerPortWithName(onExit, _onExitName(isolateId));
    }
    if (onError != null) {
      IsolateNameServer.registerPortWithName(onError, _onErrorName(isolateId));
    }

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

  final sendName = _sendName(isolateId);
  final send = IsolateNameServer.lookupPortByName(sendName);
  if (send == null) throw StateError('SendPort not registered');
  IsolateNameServer.removePortNameMapping(sendName);

  final onExitName = _onExitName(isolateId);
  final onExit = IsolateNameServer.lookupPortByName(onExitName);
  if (onExit != null) {
    Isolate.current.addOnExitListener(onExit);
    IsolateNameServer.removePortNameMapping(onExitName);
  }

  final onErrorName = _onErrorName(isolateId);
  final onError = IsolateNameServer.lookupPortByName(onErrorName);
  if (onError != null) {
    Isolate.current.addErrorListener(onError);
    IsolateNameServer.removePortNameMapping(onErrorName);
  }

  final userEntryPointHandle = int.parse(args[1]);
  final userEntryPoint = PluginUtilities.getCallbackFromHandle(
    CallbackHandle.fromRawHandle(userEntryPointHandle),
  );

  if (userEntryPoint == null) throw StateError('User entry point not found');

  userEntryPoint(send);
}
