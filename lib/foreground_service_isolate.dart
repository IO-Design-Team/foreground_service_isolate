
import 'foreground_service_isolate_platform_interface.dart';

class ForegroundServiceIsolate {
  Future<String?> getPlatformVersion() {
    return ForegroundServiceIsolatePlatform.instance.getPlatformVersion();
  }
}
