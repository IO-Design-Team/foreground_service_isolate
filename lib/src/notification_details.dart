import 'package:flutter/foundation.dart';

/// Notification details
@immutable
class NotificationDetails {
  /// Notification channel ID
  final String channelId;

  /// Notification channel name
  final String channelName;

  /// Notification ID
  final int id;

  /// Notification content title
  final String contentTitle;

  /// Notification content text
  final String contentText;

  /// Constructor
  const NotificationDetails({
    required this.channelId,
    required this.channelName,
    required this.id,
    required this.contentTitle,
    required this.contentText,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'channelName': channelName,
        'id': id,
        'contentTitle': contentTitle,
        'contentText': contentText,
      };
}
