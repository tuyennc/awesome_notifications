import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/enumerators/notification_action_type.dart';
import 'package:awesome_notifications/src/enumerators/notification_layout.dart';
import 'package:awesome_notifications/src/enumerators/notification_life_cycle.dart';
import 'package:awesome_notifications/src/enumerators/notification_source.dart';
import 'package:awesome_notifications/src/models/basic_notification_content.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:flutter/material.dart';

/// Main content of notification
/// If notification has no [body] or [title], it will only be created, but not displayed to the user (background notification).
class NotificationContent extends BaseNotificationContent {
  bool? hideLargeIconOnExpand;
  int? progress;
  String? ticker;

  NotificationLifeCycle? displayedLifeCycle;

  NotificationSource? createdSource;
  NotificationLifeCycle? createdLifeCycle;

  NotificationLayout? notificationLayout;

  NotificationActionType? notificationActionType;

  bool? displayOnForeground;
  bool? displayOnBackground;

  String? createdDate;
  String? displayedDate;

  bool? locked;

  NotificationContent(
      {
      required int id,
      required channelKey,
      String? groupKey,
      String? title,
      String? body,
      String? summary,
      bool? showWhen,
      String? icon,
      String? largeIcon,
      String? bigPicture,
      String? soundSource,
      bool? autoDismissible,
      Color? color,
      Color? backgroundColor,
      Map<String, String>? payload,
      this.notificationLayout = NotificationLayout.Default,
      this.notificationActionType = NotificationActionType.BringToForeground,
      this.hideLargeIconOnExpand,
      this.locked,
      this.progress,
      this.ticker,
      this.createdSource,
      this.createdLifeCycle,
      this.displayedLifeCycle,
      this.createdDate,
      this.displayOnForeground,
      this.displayOnBackground,
      this.displayedDate
      })
      : super(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            groupKey: groupKey,
            summary: summary,
            showWhen: showWhen,
            payload: payload,
            icon: icon,
            largeIcon: largeIcon,
            bigPicture: bigPicture,
            soundSource: soundSource,
            autoDismissible: autoDismissible,
            defaultColor: color,
            backgroundColor: backgroundColor);

  @override
  NotificationContent? fromMap(Map<String, dynamic> mapData) {
    super.fromMap(mapData);

    this.hideLargeIconOnExpand = AssertUtils.extractValue(
        mapData, NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND);

    this.progress = AssertUtils.extractValue(mapData, NOTIFICATION_PROGRESS);
    this.ticker = AssertUtils.extractValue(mapData, NOTIFICATION_TICKER);
    this.locked = AssertUtils.extractValue(mapData, NOTIFICATION_LOCKED);

    this.notificationLayout = AssertUtils.extractEnum(
        mapData, NOTIFICATION_LAYOUT, NotificationLayout.values);

    this.notificationActionType = AssertUtils.extractEnum(
        mapData, NOTIFICATION_ACTION_TYPE, NotificationActionType.values);

    this.displayedLifeCycle = AssertUtils.extractEnum(mapData,
        NOTIFICATION_DISPLAYED_LIFECYCLE, NotificationLifeCycle.values);
    this.displayedDate =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_DISPLAYED_DATE);

    this.createdSource = AssertUtils.extractEnum(
        mapData, NOTIFICATION_CREATED_SOURCE, NotificationSource.values);
    this.createdLifeCycle = AssertUtils.extractEnum(
        mapData, NOTIFICATION_CREATED_LIFECYCLE, NotificationLifeCycle.values);
    this.createdDate =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_CREATED_DATE);

    this.displayOnForeground = AssertUtils.extractValue<bool>(
        mapData, NOTIFICATION_DISPLAY_ON_FOREGROUND);
    this.displayOnBackground = AssertUtils.extractValue<bool>(
        mapData, NOTIFICATION_DISPLAY_ON_BACKGROUND);

    try {
      validate();
    } catch (e) {
      return null;
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> dataMap = super.toMap();

    dataMap = dataMap
      ..addAll({
        NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: hideLargeIconOnExpand,
        NOTIFICATION_PROGRESS: progress,
        NOTIFICATION_TICKER: ticker,
        NOTIFICATION_LOCKED: locked,
        NOTIFICATION_LAYOUT: AssertUtils.toSimpleEnumString(notificationLayout),
        NOTIFICATION_CREATED_DATE: createdDate,
        NOTIFICATION_CREATED_SOURCE:
            AssertUtils.toSimpleEnumString(createdSource),
        NOTIFICATION_CREATED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(createdLifeCycle),
        NOTIFICATION_DISPLAYED_DATE: displayedDate,
        NOTIFICATION_DISPLAYED_LIFECYCLE:
            AssertUtils.toSimpleEnumString(displayedLifeCycle),
        NOTIFICATION_ACTION_TYPE: AssertUtils.toSimpleEnumString(notificationActionType),
        NOTIFICATION_DISPLAY_ON_FOREGROUND: displayOnForeground,
        NOTIFICATION_DISPLAY_ON_BACKGROUND: displayOnBackground,
      });
    return dataMap;
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}
