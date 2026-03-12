# foreground_service_isolate

Helper to spawn a long-running isolate that supports Flutter plugins in an Android foreground service. Sets up isolate channel communication with [isolate_channel](https://pub.dev/packages/isolate_channel).

## Getting Started

android/app/src/main/AndroidManifest.xml:

```xml
<manifest>
    {YOUR PERMISSIONS HERE}

    <application>
        <service
            android:name="com.iodesignteam.foreground_service_isolate.IsolateForegroundService"
            android:exported="false"
            android:foregroundServiceType="{YOUR SERVICE TYPES HERE}" />
    </application>
</manifest>
```

See the [foreground service types documentation](https://developer.android.com/develop/background-work/services/fgs/service-types) for information on what types and permissions to declare based on your use case

## Usage

<!-- embedme example/readme/usage.dart -->
```dart
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

const methodChannelId = 'foreground_service_isolate_method';

void example() async {
  // Notification permission is required to show a foreground service notification
  await Permission.notification.request();

  final connection = await spawnForegroundServiceIsolate(
    isolateEntryPoint,
    notificationDetails: const NotificationDetails(
      channelId: 'foreground_service_isolate',
      channelName: 'Foreground Service Isolate',
      id: 1,
      contentTitle: 'Foreground Service Isolate',
      contentText: 'Running...',
      // This resource must be present in android/app/src/main/res/drawable
      smallIcon: 'ic_launcher',
      // Optional: make notification swipe-dismissable
      dismissible: false,
      // Optional: configure notification tap behavior
      tapAction: NotificationTapAction.launchDeepLink,
      tapDeepLink: 'foreground-service-isolate://session',
    ),
  );

  final methodChannel = IsolateMethodChannel(methodChannelId, connection);
  final result = await methodChannel.invokeMethod('ping');
  debugPrint(result);
}

@pragma('vm:entry-point')
void isolateEntryPoint(SendPort? send) {
  final connection = setupIsolate(send);

  final methodChannel = IsolateMethodChannel(methodChannelId, connection);
  methodChannel.setMethodCallHandler(
    (call) => switch (call.method) {
      'ping' => 'pong',
      _ => call.notImplemented(),
    },
  );
}

```

### Notification Tap Behavior

`NotificationDetails.tapAction` supports:

- `NotificationTapAction.launchApp` (default): opens the app launcher activity.
- `NotificationTapAction.none`: disables tap handling.
- `NotificationTapAction.launchDeepLink`: launches an `ACTION_VIEW` intent using `tapDeepLink`.
- `NotificationTapAction.launchIntentAction`: launches a custom Android intent action using `tapIntentAction`.

When using `launchDeepLink` or `launchIntentAction`, set `tapDeepLink` or `tapIntentAction` respectively.

### Notification Dismiss Behavior

- `dismissible: false` (default) marks the foreground notification as ongoing (`setOngoing(true)`).
- `dismissible: true` allows the notification to be swiped away.

Note: On Android 14+ (API 34+), users may still be able to dismiss some foreground service
notifications even when `dismissible: false` is set.

See the [isolate_channel documentation](https://pub.dev/packages/isolate_channel) for more information on how to use isolate connections
