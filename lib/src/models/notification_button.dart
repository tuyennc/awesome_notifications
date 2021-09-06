import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_action_type.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';

/// Notification button to display inside a notification.
/// Since Android 7, icons are displayed only for Media Layout Notifications
/// [icon] must be a native resource media type
///
/// [buttonType] could be classified in 4 types:
///
/// [NotificationActionButton.Default]: after user taps, the notification bar is closed and an action event is fired.
/// [NotificationActionButton.InputField]: after user taps, a input text field is displayed to capture input by the user.
/// [NotificationActionButton.DisabledAction]: after user taps, the notification bar is closed, but the respective action event is not fired.
/// [NotificationActionButton.KeepOnTop]: after user taps, the notification bar is not closed, but an action event is fired.
class NotificationActionButton extends Model {
  String key;
  String label;
  String? icon;

  bool? enabled;
  bool? autoDismissible;
  bool? requireInputText;

  NotificationActionType? notificationActionType;

  NotificationActionButton({
    required this.key,
    required this.label,
    this.icon,
    this.enabled = true,
    this.autoDismissible = true,
    this.requireInputText = false,
    this.notificationActionType = NotificationActionType.BringToForeground,
  });

  NotificationActionButton.asDefault({
    required this.key,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.autoDismissible = true,
    this.requireInputText = false,
    this.notificationActionType = NotificationActionType.BringToForeground,
  });

  NotificationActionButton.asDefaultSilentAction({
    required this.key,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.autoDismissible = true,
    this.requireInputText = false,
    this.notificationActionType = NotificationActionType.SilentAction,
  });

  NotificationActionButton.asDisabledAction({
    required this.key,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.autoDismissible = false,
    this.requireInputText = false,
    this.notificationActionType = NotificationActionType.DisabledAction,
  });

  NotificationActionButton.asKeepOnTop({
    required this.key,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.autoDismissible = false,
    this.requireInputText = false,
    this.notificationActionType = NotificationActionType.SilentAction,
  });

  NotificationActionButton.asInputText({
    required this.key,
    required this.label,
    required this.icon,
    required this.notificationActionType,
    this.enabled = true,
    this.autoDismissible = true,
    this.requireInputText = true,
  });

  @override
  NotificationActionButton? fromMap(Map<String, dynamic> dataMap) {

    key   = AssertUtils.extractValue(dataMap, NOTIFICATION_KEY);
    icon  = AssertUtils.extractValue(dataMap, NOTIFICATION_ICON);
    label = AssertUtils.extractValue(dataMap, NOTIFICATION_BUTTON_LABEL);

    enabled = AssertUtils.extractValue(dataMap, NOTIFICATION_ENABLED);
    autoDismissible = AssertUtils.extractValue(dataMap, NOTIFICATION_AUTO_DISMISSIBLE);
    requireInputText = AssertUtils.extractValue(dataMap, NOTIFICATION_REQUIRE_INPUT_TEXT);
    notificationActionType = AssertUtils.extractEnum(
        dataMap, NOTIFICATION_ACTION_TYPE, NotificationActionType.values);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_KEY: key,
      NOTIFICATION_ICON: icon,
      NOTIFICATION_BUTTON_LABEL: label,
      NOTIFICATION_ENABLED: enabled,
      NOTIFICATION_AUTO_DISMISSIBLE: autoDismissible,
      NOTIFICATION_REQUIRE_INPUT_TEXT: requireInputText,
      NOTIFICATION_ACTION_TYPE: AssertUtils.toSimpleEnumString(notificationActionType)
    };
  }

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(key, String));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(label, String));

    // For action buttons, it's only allowed resource media types
    assert(StringUtils.isNullOrEmpty(icon) ||
        BitmapUtils().getMediaSource(icon!) == MediaSource.Resource);
  }
}
