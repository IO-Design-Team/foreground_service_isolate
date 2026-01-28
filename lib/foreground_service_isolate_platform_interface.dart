import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'foreground_service_isolate_method_channel.dart';

abstract class ForegroundServiceIsolatePlatform extends PlatformInterface {
  /// Constructs a ForegroundServiceIsolatePlatform.
  ForegroundServiceIsolatePlatform() : super(token: _token);

  static final Object _token = Object();

  static ForegroundServiceIsolatePlatform _instance = MethodChannelForegroundServiceIsolate();

  /// The default instance of [ForegroundServiceIsolatePlatform] to use.
  ///
  /// Defaults to [MethodChannelForegroundServiceIsolate].
  static ForegroundServiceIsolatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ForegroundServiceIsolatePlatform] when
  /// they register themselves.
  static set instance(ForegroundServiceIsolatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
