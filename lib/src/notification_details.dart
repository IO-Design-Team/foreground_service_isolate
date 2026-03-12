import 'package:flutter/foundation.dart';
import 'package:foreground_service_isolate/src/notification_importance.dart';

/// Notification tap behavior
enum NotificationTapAction {
  /// Disable notification tap handling
  none('none'),

  /// Launch the host app's launcher activity
  launchApp('launchApp'),

  /// Launch an `ACTION_VIEW` intent using [NotificationDetails.tapDeepLink]
  launchDeepLink('launchDeepLink'),

  /// Launch a custom intent action using [NotificationDetails.tapIntentAction]
  launchIntentAction('launchIntentAction');

  /// Constructor
  const NotificationTapAction(this.value);

  /// Serialized value sent to native platforms
  final String value;
}

/// Notification details
@immutable
class NotificationDetails {
  /// Notification channel ID
  final String channelId;

  /// Notification channel name
  final String channelName;

  /// Notification channel description
  final String? channelDescription;

  /// Notification ID
  final int id;

  /// Notification content title
  final String contentTitle;

  /// Notification content text
  final String contentText;

  /// Notification small icon
  final String smallIcon;

  /// Notification importance
  final NotificationImportance importance;

  /// Whether the notification can be dismissed by swiping.
  ///
  /// Defaults to `false` to keep the foreground service notification ongoing.
  final bool dismissible;

  /// Notification tap behavior
  final NotificationTapAction tapAction;

  /// Deep link used when [tapAction] is [NotificationTapAction.launchDeepLink]
  final String? tapDeepLink;

  /// Intent action used when [tapAction] is [NotificationTapAction.launchIntentAction]
  final String? tapIntentAction;

  /// Constructor
  const NotificationDetails({
    required this.channelId,
    required this.channelName,
    this.channelDescription,
    required this.id,
    required this.contentTitle,
    required this.contentText,
    required this.smallIcon,
    this.importance = NotificationImportance.defaultImportance,
    this.dismissible = false,
    this.tapAction = NotificationTapAction.launchApp,
    this.tapDeepLink,
    this.tapIntentAction,
  })  : assert(
          tapAction != NotificationTapAction.launchDeepLink ||
              (tapDeepLink != null && tapDeepLink != ''),
          'tapDeepLink must be provided when tapAction is launchDeepLink',
        ),
        assert(
          tapAction != NotificationTapAction.launchIntentAction ||
              (tapIntentAction != null && tapIntentAction != ''),
          'tapIntentAction must be provided when tapAction is launchIntentAction',
        );

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'channelName': channelName,
        'channelDescription': channelDescription,
        'id': id,
        'contentTitle': contentTitle,
        'contentText': contentText,
        'smallIcon': smallIcon,
        'importance': importance.value,
        'dismissible': dismissible,
        'tapAction': tapAction.value,
        'tapDeepLink': tapDeepLink,
        'tapIntentAction': tapIntentAction,
      };
}
