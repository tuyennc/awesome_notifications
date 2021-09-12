
import Foundation

public enum Definitions {
    
    public static let  BROADCAST_FCM_TOKEN = "me.carda.awesome_notifications.firebase.TOKEN"
    public static let  EXTRA_BROADCAST_FCM_TOKEN = "token"

    public static let  MEDIA_VALID_NETWORK = "^https?:\\/\\/"//(www)?(\\.?[a-zA-Z0-9@:%.\\-_\\+~#=]{2,256}\\/?)+(\\?\\S+)$
    public static let  MEDIA_VALID_FILE = "^file:\\/\\/"
    public static let  MEDIA_VALID_ASSET = "^asset:\\/\\/"
    public static let  MEDIA_VALID_RESOURCE = "^resource:\\/\\/"

    public static let  INITIALIZE_CHANNELS = "initializeChannels"
    
    public static let  USER_DEFAULT_TAG = "group." + Bundle.main.getBundleName().md5
    public static let  DEFAULT_CATEGORY_IDENTIFIER = "DEFAULT"

    public static let  IOS_BACKGROUND_SCHEDULER = "awesome_notifications.scheduler"
    public static let  BROADCAST_CREATED_NOTIFICATION = "broadcast.awesome_notifications.CREATED_NOTIFICATION"
    public static let  BROADCAST_DISPLAYED_NOTIFICATION = "broadcast.awesome_notifications.DISPLAYED_NOTIFICATION"
    public static let  BROADCAST_KEEP_ON_TOP = "broadcast.awesome_notifications.KEEP_ON_TOP"
    public static let  EXTRA_BROADCAST_MESSAGE = "notification"

    public static let  ACTION_HANDLE = "actionHandle"
    public static let  SILENT_HANDLE = "silentHandle"
    public static let  DART_BG_HANDLE = "dartBgHandle"
    
    public static let  PUSH_NOTIFICATION_CONTENT = "content"
    public static let  PUSH_NOTIFICATION_SCHEDULE = "schedule"
    public static let  PUSH_NOTIFICATION_BUTTONS = "actionButtons"

    public static let  SHARED_DEFAULTS = "defaults"
    public static let  SHARED_MANAGER = "sharedManager"
    public static let  SHARED_CHANNELS = "channels"
    public static let  SHARED_CREATED = "created"
    public static let  SHARED_DISPLAYED = "displayed"
    public static let  SHARED_SCHEDULED_NOTIFICATIONS = "schedules"
    public static let  SHARED_SCHEDULED_DISPLAYED = "scheduledDisplayed"
    public static let  SHARED_SCHEDULED_DISPLAYED_REFERENCE = "pendingList"

    public static let  NOTIFICATION_SCHEDULE_INITIAL_DATE = "createdDate"
    public static let  NOTIFICATION_SCHEDULE_TIMEZONE = "timeZone"
    public static let  NOTIFICATION_SCHEDULE_ERA = "era"
    public static let  NOTIFICATION_SCHEDULE_YEAR = "year"
    public static let  NOTIFICATION_SCHEDULE_MONTH = "month"
    public static let  NOTIFICATION_SCHEDULE_DAY = "day"
    public static let  NOTIFICATION_SCHEDULE_HOUR = "hour"
    public static let  NOTIFICATION_SCHEDULE_MINUTE = "minute"
    public static let  NOTIFICATION_SCHEDULE_SECOND = "second"
    public static let  NOTIFICATION_SCHEDULE_MILLISECOND = "millisecond"
    public static let  NOTIFICATION_SCHEDULE_WEEKDAY = "weekday"
    public static let  NOTIFICATION_SCHEDULE_WEEKOFMONTH = "weekOfMonth"
    public static let  NOTIFICATION_SCHEDULE_WEEKOFYEAR = "weekOfYear"
    public static let  NOTIFICATION_SCHEDULE_INTERVAL = "interval"
    public static let  NOTIFICATION_SCHEDULE_REPEATS = "repeats"
    
    public static let  CHANNEL_FLUTTER_PLUGIN = "awesome_notifications"

    public static let  CHANNEL_METHOD_INITIALIZE = "initialize"
    public static let  CHANNEL_METHOD_GET_DRAWABLE_DATA = "getDrawableData"
    public static let  CHANNEL_METHOD_CREATE_NOTIFICATION = "createNewNotification"

    public static let  CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken"
    public static let  CHANNEL_METHOD_NEW_FCM_TOKEN = "newTokenReceived"
    public static let  CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable"

    public static let  CHANNEL_METHOD_SET_ACTION_HANDLE = "setActionHandle"
    public static let  CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL = "setNotificationChannel"
    public static let  CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL = "removeNotificationChannel"

    public static let  CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE = "showNotificationPage"
    public static let  CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED = "isNotificationAllowed"
    public static let  CHANNEL_METHOD_REQUEST_NOTIFICATIONS = "requestNotifications"
    
    public static let  CHANNEL_METHOD_GET_BADGE_COUNT = "getBadgeCount"
    public static let  CHANNEL_METHOD_SET_BADGE_COUNT = "setBadgeCount"
    public static let  CHANNEL_METHOD_GET_NEXT_DATE = "getNextDate"
    public static let  CHANNEL_METHOD_RESET_BADGE = "resetBadge"
    public static let  CHANNEL_METHOD_DISMISS_NOTIFICATION = "dismissNotification"
    public static let  CHANNEL_METHOD_CANCEL_NOTIFICATION = "cancelNotification"
    public static let  CHANNEL_METHOD_CANCEL_SCHEDULE = "cancelSchedule"
    public static let  CHANNEL_METHOD_CANCEL_ALL_SCHEDULES = "cancelAllSchedules"
    public static let  CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS = "dismissAllNotifications"
    public static let  CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS = "cancelAllNotifications"

    public static let  CHANNEL_METHOD_NOTIFICATION_CREATED = "notificationCreated"
    public static let  CHANNEL_METHOD_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    public static let  CHANNEL_METHOD_NOTIFICATION_DISMISSED = "notificationDismissed"
    public static let  CHANNEL_METHOD_RECEIVED_ACTION = "receivedAction"
    
    public static let  CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER = "getUtcTimeZoneIdentifier"
    public static let  CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER = "getLocalTimeZoneIdentifier"
    
    public static let  CHANNEL_METHOD_LIST_ALL_SCHEDULES = "listAllSchedules"

    public static let  DEFAULT_ICON = "defaultIcon"
    public static let  SELECT_NOTIFICATION = "SELECT_NOTIFICATION"
    public static let  NOTIFICATION_BUTTON_ACTION_PREFIX = "ACTION_NOTIFICATION"

    public static let  SHARED_PREFERENCES_CHANNEL_MANAGER = "channel_manager"
    
    public static let  DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
    
    public static let  DATE_FORMAT_TIMEZONE = "yyyy-MM-dd HH:mm:ss ZZZZ"

    public static let  NOTIFICATION_ICON_RESOURCE_ID = "iconResourceId"

    public static let  NOTIFICATION_CREATED_SOURCE = "createdSource"
    public static let  NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle"
    public static let  NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    public static let  NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle"
    public static let  NOTIFICATION_DISMISSED_LIFECYCLE = "dismissedLifeCycle"
    public static let  NOTIFICATION_CREATED_DATE = "createdDate"
    public static let  NOTIFICATION_DISPLAYED_DATE = "displayedDate"
    public static let  NOTIFICATION_ACTION_DATE = "actionDate"
    public static let  NOTIFICATION_DISMISSED_DATE = "dismissedDate"

    public static let  NOTIFICATION_ID = "id"
    public static let  NOTIFICATION_LAYOUT = "notificationLayout"
    public static let  NOTIFICATION_TITLE = "title"
    public static let  NOTIFICATION_BODY = "body"
    public static let  NOTIFICATION_SUMMARY = "summary"
    public static let  NOTIFICATION_SHOW_WHEN = "showWen"
    public static let  NOTIFICATION_ACTION_KEY = "actionKey"
    public static let  NOTIFICATION_ACTION_INPUT = "actionInput"
    public static let  NOTIFICATION_JSON = "notificationJson"

    public static let  NOTIFICATION_ACTION_BUTTONS = "actionButtons"
    public static let  NOTIFICATION_BUTTON_KEY = "key"
    public static let  NOTIFICATION_BUTTON_ICON = "icon"
    public static let  NOTIFICATION_BUTTON_LABEL = "label"
    public static let  NOTIFICATION_BUTTON_TYPE = "buttonType"

    public static let  NOTIFICATION_PAYLOAD = "payload"
    public static let  NOTIFICATION_INITIAL_FIXED_DATE = "fixedDate"
    public static let  NOTIFICATION_INITIAL_DATE_TIME = "createdDateTime"
    public static let  NOTIFICATION_CRONTAB_SCHEDULE = "crontabSchedule"
    public static let  NOTIFICATION_ENABLED = "enabled"
    public static let  NOTIFICATION_AUTO_CANCEL = "autoCancel"
    public static let  NOTIFICATION_LOCKED = "locked"
    
    public static let  NOTIFICATION_DISPLAY_ON_FOREGROUND = "displayOnForeground"
    public static let  NOTIFICATION_DISPLAY_ON_BACKGROUND = "displayOnBackground"
    
    public static let  NOTIFICATION_ICON = "icon"
    public static let  NOTIFICATION_PLAY_SOUND = "playSound"
    public static let  NOTIFICATION_SOUND_SOURCE = "soundSource"
    public static let  NOTIFICATION_DEFAULT_RINGTONE_TYPE = "defaultRingtoneType"
    public static let  NOTIFICATION_ENABLE_VIBRATION = "enableVibration"
    public static let  NOTIFICATION_VIBRATION_PATTERN = "vibrationPattern"
    public static let  NOTIFICATION_GROUP_KEY = "groupKey"
    public static let  NOTIFICATION_GROUP_SORT = "groupSort"
    public static let  NOTIFICATION_GROUP_ALERT_BEHAVIOR = "groupAlertBehaviour"
    public static let  NOTIFICATION_PRIVACY = "privacy"
    public static let  NOTIFICATION_DEFAULT_PRIVACY = "defaultPrivacy"
    public static let  NOTIFICATION_PRIVATE_MESSAGE = "privateMessage"
    public static let  NOTIFICATION_ONLY_ALERT_ONCE = "onlyAlertOnce"
    public static let  NOTIFICATION_CHANNEL_KEY = "channelKey"
    public static let  NOTIFICATION_CHANNEL_NAME = "channelName"
    public static let  NOTIFICATION_CHANNEL_DESCRIPTION = "channelDescription"
    public static let  NOTIFICATION_CHANNEL_SHOW_BADGE = "channelShowBadge"
    public static let  NOTIFICATION_IMPORTANCE = "importance"
    public static let  NOTIFICATION_BACKGROUND_COLOR = "backgroundColor"
    public static let  NOTIFICATION_DEFAULT_COLOR = "defaultColor"
    public static let  NOTIFICATION_LARGE_ICON = "largeIcon"
    public static let  NOTIFICATION_BIG_PICTURE = "bigPicture"
    public static let  NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND = "hideLargeIconOnExpand"
    public static let  NOTIFICATION_PROGRESS = "progress"
    public static let  NOTIFICATION_ENABLE_LIGHTS = "enableLights"
    public static let  NOTIFICATION_LED_COLOR = "ledColor"
    public static let  NOTIFICATION_LED_ON_MS = "ledOnMs"
    public static let  NOTIFICATION_LED_OFF_MS = "ledOffMs"
    public static let  NOTIFICATION_TICKER = "ticker"
    public static let  NOTIFICATION_ALLOW_WHILE_IDLE = "allowWhileIdle"

    public static let  initialValues = [
        Definitions.NOTIFICATION_ID: 0,
        Definitions.NOTIFICATION_SCHEDULE_REPEATS: false,
        Definitions.NOTIFICATION_IMPORTANCE: NotificationImportance.Default,
        Definitions.NOTIFICATION_LAYOUT: NotificationLayout.Default,
        Definitions.NOTIFICATION_GROUP_SORT: GroupSort.Desc,
        Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR: GroupAlertBehaviour.All,
        Definitions.NOTIFICATION_DEFAULT_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_CREATED_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_ACTION_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND: true,
        Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND: true,
        Definitions.NOTIFICATION_CHANNEL_KEY: "miscellaneous",
        Definitions.NOTIFICATION_CHANNEL_DESCRIPTION: "Notifications",
        Definitions.NOTIFICATION_CHANNEL_NAME: "Notifications",
        Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE: DefaultRingtoneType.Notification,
        Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE: false,
        Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: false,
        Definitions.NOTIFICATION_ENABLED: true,
        Definitions.NOTIFICATION_SHOW_WHEN: true,
        Definitions.NOTIFICATION_BUTTON_TYPE: ActionButtonType.Default,
        Definitions.NOTIFICATION_PAYLOAD: nil,
        Definitions.NOTIFICATION_ENABLE_VIBRATION: true,
        Definitions.NOTIFICATION_DEFAULT_COLOR: 0x000000,
        Definitions.NOTIFICATION_LED_COLOR: 0xFFFFFF,
        Definitions.NOTIFICATION_ENABLE_LIGHTS: true,
        Definitions.NOTIFICATION_LED_OFF_MS: 700,
        Definitions.NOTIFICATION_LED_ON_MS: 300,
        Definitions.NOTIFICATION_PLAY_SOUND: true,
        Definitions.NOTIFICATION_AUTO_CANCEL: true,
        Definitions.NOTIFICATION_LOCKED: false,
        Definitions.NOTIFICATION_TICKER: "ticker",
        Definitions.NOTIFICATION_ALLOW_WHILE_IDLE: false,
        Definitions.NOTIFICATION_ONLY_ALERT_ONCE: false
    ] as [String : Any?]
}
