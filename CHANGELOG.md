## 0.1.2

- Adds `launchAppOnTap` to enable/disable launching the app when the foreground notification is tapped
- Adds `dismissible` to control whether the foreground notification can be swiped away
- Fixes Android service startup ordering by calling `FlutterLoader.startInitialization`
  before `ensureInitializationComplete`
- Adds a notification content intent so tapping the foreground notification can launch the app when enabled

## 0.1.1

- Adds optional `channelDescription` and `importance` to `NotificationDetails`
- Fixes minification issue in release builds

## 0.1.0

- Initial release
