/// The importance of a notification
///
/// https://developer.android.com/reference/android/app/NotificationManager
enum NotificationImportance {
  /// Default notification importance: shows everywhere, makes noise, but does
  /// not visually intrude.
  defaultImportance(3),

  /// Higher notification importance: shows everywhere, makes noise and peeks.
  /// May use full screen intents.
  high(4),

  /// Low notification importance: Shows in the shade, and potentially in the
  /// status bar (see shouldHideSilentStatusBarIcons()), but is not audibly
  /// intrusive.
  low(2),

  /// Unused.
  max(5),

  /// Min notification importance: only shows in the shade, below the fold. This
  /// should not be used with Service.startForeground since a foreground service
  /// is supposed to be something the user cares about so it does not make
  /// semantic sense to mark its notification as minimum importance. If you do
  /// this as of Android version Build.VERSION_CODES.O, the system will show a
  /// higher-priority notification about your app running in the background.
  min(1),

  /// A notification with no importance: does not show in the shade.
  none(0);

  /// Constructor
  const NotificationImportance(this.value);

  /// The integer value
  final int value;
}
