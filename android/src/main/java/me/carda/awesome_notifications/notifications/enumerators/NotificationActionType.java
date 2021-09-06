package me.carda.awesome_notifications.notifications.enumerators;

public enum NotificationActionType {

    /// Forces the app to go foreground and run on main thread calling actionStream. Can be interrupt if app gets terminated.
    BringToForeground,

    /// Do not forces the app to go foreground and do not closes the status bar, but calls actionStream
    KeepOnTopAction,

    /// Do not do anything and don't dismiss the corresponding notification.
    DisabledAction,

    /// Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
    silentAction

    // TODO missing implementation. Flutter engine does not accept to run on background thread, yet.
    /// Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is totally
    /// apart from app lifecycle and will not be interrupt if the app goes terminated / killed.
    /// SilentBackgroundThread
}
