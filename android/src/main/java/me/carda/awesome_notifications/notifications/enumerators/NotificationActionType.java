package me.carda.awesome_notifications.notifications.enumerators;

public enum NotificationActionType {

    /// Forces the app to go foreground and run on main thread calling actionStream. Can be interrupt if app gets terminated.
    BringToForeground,

    /// Do not forces the app to go foreground and do not closes the status bar, but fires the action event
    KeepOnTopAction,

    /// Do not do fire any action event and only runs on native level.
    DisabledAction,

    /// Do not forces the app to go foreground, but runs silently on main thread, accept visual elements and can be interrupt if main app gets terminated.
    /// It can run while the app is terminated / killed
    SilentAction,

    /// Do not forces the app to go foreground and runs silently on background, do not accept any visual elements. The execution is totally
    /// apart from app lifecycle and will not be interrupt if the app goes terminated / killed.
    SilentBackgroundAction
}
