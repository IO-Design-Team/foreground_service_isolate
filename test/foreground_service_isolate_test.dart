import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:foreground_service_isolate/foreground_service_isolate_platform_interface.dart';
import 'package:foreground_service_isolate/foreground_service_isolate_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockForegroundServiceIsolatePlatform
    with MockPlatformInterfaceMixin
    implements ForegroundServiceIsolatePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ForegroundServiceIsolatePlatform initialPlatform = ForegroundServiceIsolatePlatform.instance;

  test('$MethodChannelForegroundServiceIsolate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelForegroundServiceIsolate>());
  });

  test('getPlatformVersion', () async {
    ForegroundServiceIsolate foregroundServiceIsolatePlugin = ForegroundServiceIsolate();
    MockForegroundServiceIsolatePlatform fakePlatform = MockForegroundServiceIsolatePlatform();
    ForegroundServiceIsolatePlatform.instance = fakePlatform;

    expect(await foregroundServiceIsolatePlugin.getPlatformVersion(), '42');
  });
}
