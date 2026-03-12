## 0.1.2

- Adds configurable foreground-notification tap behavior with `NotificationTapAction`
  (`launchApp`, `none`, `launchDeepLink`, `launchIntentAction`)
- Adds `tapDeepLink` and `tapIntentAction` to support custom tap targets
- Adds `dismissible` to control whether the foreground notification can be swiped away
- Fixes Android service startup ordering by calling `FlutterLoader.startInitialization`
  before `ensureInitializationComplete`
- Adds a notification content intent so tapping the foreground notification can launch app/deep-link/action flows

## 0.1.1

- Adds optional `channelDescription` and `importance` to `NotificationDetails`
- Fixes minification issue in release builds

## 0.1.0

- Initial release
