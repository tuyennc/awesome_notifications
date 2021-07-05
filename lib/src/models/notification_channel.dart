import 'dart:typed_data';

import 'package:awesome_notifications/src/enumerators/default_ringtone_type.dart';
import 'package:awesome_notifications/src/enumerators/group_alert_behaviour.dart';
import 'package:awesome_notifications/src/enumerators/group_sort.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/enumerators/notification_importance.dart';
import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/string_utils.dart';
import 'package:flutter/material.dart';

import '../../definitions.dart';

/// A representation of default settings that applies to all notifications with same channel key
/// [soundSource] needs to be a native resource media type
class NotificationChannel extends Model {
  String? channelKey;
  String? channelName;
  String? channelDescription;
  bool? channelShowBadge;

  NotificationImportance? importance;

  bool? playSound;
  String? soundSource;
  DefaultRingtoneType? defaultRingtoneType;

  bool? enableVibration;
  Int64List? vibrationPattern;

  bool? enableLights;
  Color? ledColor;
  int? ledOnMs;
  int? ledOffMs;

  String? groupKey;
  GroupSort? groupSort;
  GroupAlertBehavior? groupAlertBehavior;

  NotificationPrivacy? defaultPrivacy;

  String? icon;
  Color? defaultColor;

  bool? locked;
  bool? onlyAlertOnce;

  NotificationChannel({
    this.channelKey,
    this.channelName,
    this.channelDescription,
    this.channelShowBadge,
    this.importance,
    this.playSound,
    this.soundSource,
    this.defaultRingtoneType,
    this.enableVibration,
    this.vibrationPattern,
    this.enableLights,
    this.ledColor,
    this.ledOnMs,
    this.ledOffMs,
    this.groupKey,
    this.groupSort,
    this.groupAlertBehavior,
    this.icon,
    this.defaultColor,
    this.locked,
    this.onlyAlertOnce,
    this.defaultPrivacy,
  }) : super() {
    this.channelKey = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_KEY, this.channelKey, String);
    this.channelName = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_NAME, this.channelName, String);
    this.channelDescription = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_DESCRIPTION, this.channelDescription, String);
    this.channelShowBadge = AssertUtils.getValueOrDefault(
        NOTIFICATION_CHANNEL_SHOW_BADGE, this.channelShowBadge, bool);
    this.importance = AssertUtils.getValueOrDefault(
        NOTIFICATION_IMPORTANCE, this.importance, NotificationImportance);
    this.playSound = AssertUtils.getValueOrDefault(
        NOTIFICATION_PLAY_SOUND, this.playSound, bool);
    this.soundSource = AssertUtils.getValueOrDefault(
        NOTIFICATION_SOUND_SOURCE, this.soundSource, String);
    this.enableVibration = AssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_VIBRATION, this.enableVibration, bool);
    this.vibrationPattern = AssertUtils.getValueOrDefault(
        NOTIFICATION_VIBRATION_PATTERN, this.vibrationPattern, Int64List);
    this.enableLights = AssertUtils.getValueOrDefault(
        NOTIFICATION_ENABLE_LIGHTS, this.enableLights, bool);
    this.ledColor = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_COLOR, this.ledColor, Color);
    this.ledOnMs = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_ON_MS, this.ledOnMs, int);
    this.ledOffMs = AssertUtils.getValueOrDefault(
        NOTIFICATION_LED_OFF_MS, this.ledOffMs, int);
    this.groupKey = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_KEY, this.groupKey, String);
    this.groupSort = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_SORT, this.groupSort, GroupSort);
    this.groupAlertBehavior = AssertUtils.getValueOrDefault(
        NOTIFICATION_GROUP_ALERT_BEHAVIOR,
        this.groupAlertBehavior,
        GroupAlertBehavior);
    this.icon =
        AssertUtils.getValueOrDefault(NOTIFICATION_ICON, this.icon, String);
    this.defaultColor = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_COLOR, this.defaultColor, Color);
    this.locked =
        AssertUtils.getValueOrDefault(NOTIFICATION_LOCKED, this.locked, bool);
    this.onlyAlertOnce = AssertUtils.getValueOrDefault(
        NOTIFICATION_ONLY_ALERT_ONCE, this.onlyAlertOnce, bool);
    this.defaultPrivacy = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_PRIVACY, this.defaultPrivacy, NotificationPrivacy);
    this.defaultRingtoneType = AssertUtils.getValueOrDefault(
        NOTIFICATION_DEFAULT_RINGTONE_TYPE,
        this.defaultRingtoneType,
        DefaultRingtoneType);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      NOTIFICATION_ICON: icon,
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_CHANNEL_NAME: channelName,
      NOTIFICATION_CHANNEL_DESCRIPTION: channelDescription,
      NOTIFICATION_CHANNEL_SHOW_BADGE: channelShowBadge,
      NOTIFICATION_IMPORTANCE: AssertUtils.toSimpleEnumString(importance),
      NOTIFICATION_PLAY_SOUND: playSound,
      NOTIFICATION_SOUND_SOURCE: soundSource,
      NOTIFICATION_ENABLE_VIBRATION: enableVibration,
      NOTIFICATION_VIBRATION_PATTERN: vibrationPattern,
      NOTIFICATION_ENABLE_LIGHTS: enableLights,
      NOTIFICATION_DEFAULT_COLOR: defaultColor?.value,
      NOTIFICATION_LED_COLOR: ledColor?.value,
      NOTIFICATION_LED_ON_MS: ledOnMs,
      NOTIFICATION_LED_OFF_MS: ledOffMs,
      NOTIFICATION_GROUP_KEY: groupKey,
      NOTIFICATION_GROUP_SORT: AssertUtils.toSimpleEnumString(groupSort),
      NOTIFICATION_GROUP_ALERT_BEHAVIOR:
          AssertUtils.toSimpleEnumString(groupAlertBehavior),
      NOTIFICATION_DEFAULT_PRIVACY:
          AssertUtils.toSimpleEnumString(defaultPrivacy),
      NOTIFICATION_DEFAULT_RINGTONE_TYPE:
          AssertUtils.toSimpleEnumString(defaultRingtoneType),
      NOTIFICATION_LOCKED: locked,
      NOTIFICATION_ONLY_ALERT_ONCE: onlyAlertOnce
    };
  }

  NotificationChannel fromMap(Map<String, dynamic> dataMap) {
    this.channelKey =
        AssertUtils.extractValue(dataMap, NOTIFICATION_CHANNEL_KEY);
    this.channelName =
        AssertUtils.extractValue(dataMap, NOTIFICATION_CHANNEL_NAME);
    this.channelDescription =
        AssertUtils.extractValue(dataMap, NOTIFICATION_CHANNEL_DESCRIPTION);
    this.channelShowBadge =
        AssertUtils.extractValue(dataMap, NOTIFICATION_CHANNEL_SHOW_BADGE);
    this.importance = AssertUtils.extractEnum(
        dataMap, NOTIFICATION_IMPORTANCE, NotificationImportance.values);
    this.playSound = AssertUtils.extractValue(dataMap, NOTIFICATION_PLAY_SOUND);
    this.soundSource =
        AssertUtils.extractValue(dataMap, NOTIFICATION_SOUND_SOURCE);
    this.enableVibration =
        AssertUtils.extractValue(dataMap, NOTIFICATION_ENABLE_VIBRATION);
    this.vibrationPattern =
        AssertUtils.extractValue(dataMap, NOTIFICATION_VIBRATION_PATTERN);
    this.enableLights =
        AssertUtils.extractValue(dataMap, NOTIFICATION_ENABLE_LIGHTS);
    this.groupKey = AssertUtils.extractValue(dataMap, NOTIFICATION_GROUP_KEY);
    this.groupSort = AssertUtils.extractEnum(
        dataMap, NOTIFICATION_GROUP_SORT, GroupSort.values);
    this.groupAlertBehavior = AssertUtils.extractEnum(
        dataMap, NOTIFICATION_GROUP_ALERT_BEHAVIOR, GroupAlertBehavior.values);
    this.defaultPrivacy = AssertUtils.extractEnum(
        dataMap, NOTIFICATION_DEFAULT_PRIVACY, NotificationPrivacy.values);
    this.defaultRingtoneType = AssertUtils.extractEnum(dataMap,
        NOTIFICATION_DEFAULT_RINGTONE_TYPE, DefaultRingtoneType.values);
    this.icon = AssertUtils.extractValue(dataMap, NOTIFICATION_ICON);
    this.locked = AssertUtils.extractValue(dataMap, NOTIFICATION_LOCKED);
    this.onlyAlertOnce =
        AssertUtils.extractValue(dataMap, NOTIFICATION_ONLY_ALERT_ONCE);

    int defaultColorValue =
        AssertUtils.extractValue(dataMap, NOTIFICATION_DEFAULT_COLOR);
    this.defaultColor = defaultColor == null ? null : Color(defaultColorValue);

    int ledColorValue =
        AssertUtils.extractValue(dataMap, NOTIFICATION_LED_COLOR);
    this.ledColor = defaultColor == null ? null : Color(ledColorValue);

    this.ledOnMs = AssertUtils.extractValue(dataMap, NOTIFICATION_LED_ON_MS);
    this.ledOffMs = AssertUtils.extractValue(dataMap, NOTIFICATION_LED_OFF_MS);

    return this;
  }

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelKey, String));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelName, String));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelDescription, String));

    // For small icons, it's only allowed resource media types
    assert(StringUtils.isNullOrEmpty(icon) ||
        BitmapUtils().getMediaSource(icon!) == MediaSource.Resource);
  }
}
