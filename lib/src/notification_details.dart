import 'package:flutter/foundation.dart';

/// Notification details
@immutable
class NotificationDetails {
  /// Notification channel ID
  final String channelId;

  /// Notification ID
  final int id;

  /// Notification content title
  final String contentTitle;

  /// Notification content text
  final String contentText;

  /// Notification small icon
  final String smallIcon;

  /// Constructor
  const NotificationDetails({
    required this.channelId,
    required this.id,
    required this.contentTitle,
    required this.contentText,
    required this.smallIcon,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'id': id,
        'contentTitle': contentTitle,
        'contentText': contentText,
        'smallIcon': smallIcon,
      };
}
