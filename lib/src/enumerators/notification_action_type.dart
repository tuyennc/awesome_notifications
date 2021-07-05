/// Determines what thread will receive the silent action
/// [BringToForeground]: Forces the app to go foreground and run on main thread. Can be interrupt if app gets terminated.
/// [DisabledAction]: Do not do anything and don't dismiss the corresponding notification.
/// [SilentMainThread]: Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
/// [SilentBackGroundThread]: Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is totally
/// apart from app lifecycle and will not be interrupt if the app goes terminated / killed.
enum NotificationActionType {

  /// Forces the app to go foreground and run on main thread. Can be interrupt if app gets terminated.
  BringToForeground,

  /// Do not do anything and don't dismiss the corresponding notification.
  DisabledAction,

  /// Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
  SilentMainThread,

  /// Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is totally
  /// apart from app lifecycle and will not be interrupt if the app goes terminated / killed.
  SilentBackgroundThread
}
