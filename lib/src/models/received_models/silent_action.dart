import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a user action over a Notification
class SilentAction extends ReceivedNotification {
  NotificationLifeCycle? actionLifeCycle;

  String buttonKeyPressed = '';
  String buttonKeyInput = '';

  String? actionDate;

  SilentAction();

  static SilentAction fromNotificationContent(NotificationContent content) {
    SilentAction silentAction = SilentAction().fromMap(content.toMap());
    silentAction.actionDate ??= DateUtils.getUtcTextDate();
    silentAction.actionLifeCycle ??= NotificationLifeCycle.Foreground;

    return silentAction;
  }

  /// Imports data from a serializable object
  SilentAction fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    actionLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, NOTIFICATION_ACTION_LIFECYCLE, NotificationLifeCycle.values);

    actionDate =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_ACTION_DATE);

    buttonKeyPressed =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_ACTION_KEY) ??
            '';
    buttonKeyInput =
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
        NOTIFICATION_ACTION_LIFECYCLE:
          AssertUtils.toSimpleEnumString(actionLifeCycle),
        NOTIFICATION_ACTION_KEY: buttonKeyPressed,
        NOTIFICATION_ACTION_INPUT: buttonKeyInput
      });
  }
}
