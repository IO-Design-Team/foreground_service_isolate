import 'package:flutter/foundation.dart';
import 'package:foreground_service_isolate/src/notification_importance.dart';

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

  /// Whether tapping the notification should launch the app.
  ///
  /// Defaults to `true`.
  final bool launchAppOnTap;

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
    this.launchAppOnTap = true,
  });

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
        'launchAppOnTap': launchAppOnTap,
      };
}
