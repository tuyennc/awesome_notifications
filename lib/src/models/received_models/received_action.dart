import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a user action over a Notification
class ReceivedAction extends ReceivedNotification {
  NotificationLifeCycle? actionLifeCycle;
  NotificationLifeCycle? dismissedLifeCycle;

  @Deprecated("Use actionKey instead")
  String get buttonKeyPressed => actionKey;
  @Deprecated("Use actionKey instead")
  set buttonKeyPressed(String value) => actionKey = value;

  @Deprecated("Use actionInput instead")
  String get buttonKeyInput => actionInput;
  @Deprecated("Use actionInput instead")
  set buttonKeyInput(String value) => actionInput = value;

  String actionKey = '';
  String actionInput = '';

  String? actionDate;
  String? dismissedDate;

  ReceivedAction();

  static ReceivedAction fromNotificationContent(NotificationContent content) {
    ReceivedAction receivedAction = ReceivedAction().fromMap(content.toMap());

    receivedAction.actionDate ??= DateUtils.getUtcTextDate();
    receivedAction.actionLifeCycle ??= NotificationLifeCycle.Foreground;

    return receivedAction;
  }

  /// Imports data from a serializable object
  ReceivedAction fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, NOTIFICATION_ACTION_LIFECYCLE, NotificationLifeCycle.values);

    dismissedLifeCycle = AssertUtils.extractEnum(dataMap,
        NOTIFICATION_DISMISSED_LIFECYCLE, NotificationLifeCycle.values);

    notificationActionType = AssertUtils.extractEnum<NotificationActionType>(
        dataMap, NOTIFICATION_ACTION_TYPE, NotificationActionType.values);

    actionDate =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_ACTION_DATE);
    dismissedDate =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_DISMISSED_DATE);

    actionKey =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_ACTION_KEY) ??
            '';
    actionInput =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_ACTION_INPUT) ??
            '';

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        NOTIFICATION_ACTION_DATE: actionDate,
        NOTIFICATION_DISMISSED_DATE: dismissedDate,
        NOTIFICATION_ACTION_LIFECYCLE:
          AssertUtils.toSimpleEnumString(actionLifeCycle),
        NOTIFICATION_ACTION_TYPE:
          AssertUtils.toSimpleEnumString(notificationActionType),
        NOTIFICATION_DISMISSED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(dismissedLifeCycle),
        NOTIFICATION_ACTION_KEY: actionKey,
        NOTIFICATION_ACTION_INPUT: actionInput
      });
  }
}
