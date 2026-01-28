import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_service_isolate/foreground_service_isolate_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelForegroundServiceIsolate platform = MethodChannelForegroundServiceIsolate();
  const MethodChannel channel = MethodChannel('foreground_service_isolate');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
