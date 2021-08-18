import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/basic_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// All received details of a notification created or displayed on the system
/// The data field
class ReceivedNotification extends BaseNotificationContent {
  NotificationLifeCycle? displayedLifeCycle;

  NotificationSource? createdSource;
  NotificationLifeCycle? createdLifeCycle;

  String? displayedDate;
  String? createdDate;

  NotificationActionType? notificationActionType;

  ReceivedNotification fromMap(Map<String, dynamic> dataMap) {
    super.fromMap(dataMap);

    createdSource = AssertUtils.extractEnum<NotificationSource>(
        dataMap, NOTIFICATION_CREATED_SOURCE, NotificationSource.values);
    createdLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(
        dataMap, NOTIFICATION_CREATED_LIFECYCLE, NotificationLifeCycle.values);
    displayedLifeCycle = AssertUtils.extractEnum<NotificationLifeCycle>(dataMap,
        NOTIFICATION_DISPLAYED_LIFECYCLE, NotificationLifeCycle.values);
    displayedDate =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_DISPLAYED_DATE);
    createdDate =
        AssertUtils.extractValue<String>(dataMap, NOTIFICATION_CREATED_DATE);

    return this;
  }

  /// Exports all content into a serializable object
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = super.toMap();
    return map
      ..addAll({
        NOTIFICATION_CREATED_SOURCE:
            AssertUtils.toSimpleEnumString(createdSource),
        NOTIFICATION_CREATED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(createdLifeCycle),
        NOTIFICATION_DISPLAYED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(displayedLifeCycle),
        NOTIFICATION_CREATED_DATE: createdDate,
        NOTIFICATION_DISPLAYED_DATE: displayedDate
      });
  }
}
