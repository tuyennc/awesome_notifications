import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/html_utils.dart';
import 'package:flutter/material.dart';

import '../definitions.dart';

class BaseNotificationContent extends Model {

  int? id;
  String? channelKey;
  String? title;
  String? body;
  String? summary;
  bool? showWhen;
  Map<String, String>? payload;

  String? icon;
  String? largeIcon;
  String? bigPicture;
  String? soundSource;

  @Deprecated('Use autoDismissible instead')
  bool? get autoCancel => autoDismissible;
  @Deprecated('Use autoDismissible instead')
  set autoCancel(bool? value) => autoDismissible = value;

  bool? autoDismissible;
  Color? defaultColor;
  Color? backgroundColor;
  NotificationPrivacy? privacy;

  BaseNotificationContent(
      {
      this.id,
      this.channelKey,
      this.title,
      this.body,
      this.summary,
      this.showWhen,
      this.icon,
      this.largeIcon,
      this.bigPicture,
      this.autoDismissible,
      this.defaultColor,
      this.backgroundColor,
      this.payload,
      this.soundSource});

  @override
  BaseNotificationContent? fromMap(Map<String, dynamic> mapData) {
    this.id = AssertUtils.extractValue<int>(mapData, NOTIFICATION_ID);
    this.channelKey =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_CHANNEL_KEY);
    this.title = AssertUtils.extractValue<String>(mapData, NOTIFICATION_TITLE);
    this.body = AssertUtils.extractValue<String>(mapData, NOTIFICATION_BODY);
    this.summary =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_SUMMARY);
    this.showWhen =
        AssertUtils.extractValue<bool>(mapData, NOTIFICATION_SHOW_WHEN);
    this.payload =
        AssertUtils.extractMap<String, String>(mapData, NOTIFICATION_PAYLOAD);
    this.icon = AssertUtils.extractValue<String>(mapData, NOTIFICATION_ICON);
    this.largeIcon =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_LARGE_ICON);
    this.bigPicture =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_BIG_PICTURE);
    this.soundSource =
        AssertUtils.extractValue<String>(mapData, NOTIFICATION_SOUND_SOURCE);
    this.autoDismissible =
        AssertUtils.extractValue<bool>(mapData, NOTIFICATION_AUTO_DISMISSIBLE);
    this.privacy = AssertUtils.extractEnum<NotificationPrivacy>(
        mapData, NOTIFICATION_PRIVACY, NotificationPrivacy.values);

    int? colorValue =
        AssertUtils.extractValue<int>(mapData, NOTIFICATION_DEFAULT_COLOR);
    this.defaultColor = colorValue == null ? null : Color(colorValue);

    int? backgroundColorValue =
        AssertUtils.extractValue<int>(mapData, NOTIFICATION_BACKGROUND_COLOR);
    this.backgroundColor =
        backgroundColorValue == null ? null : Color(backgroundColorValue);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_ID: id,
      NOTIFICATION_CHANNEL_KEY: channelKey,
      NOTIFICATION_TITLE: title,
      NOTIFICATION_BODY: body,
      NOTIFICATION_SUMMARY: summary,
      NOTIFICATION_SHOW_WHEN: showWhen,
      NOTIFICATION_PAYLOAD: payload,
      NOTIFICATION_ICON: icon,
      NOTIFICATION_LARGE_ICON: largeIcon,
      NOTIFICATION_BIG_PICTURE: bigPicture,
      NOTIFICATION_SOUND_SOURCE: soundSource,
      NOTIFICATION_AUTO_DISMISSIBLE: autoDismissible,
      NOTIFICATION_PRIVACY: AssertUtils.toSimpleEnumString(privacy),
      NOTIFICATION_DEFAULT_COLOR: defaultColor?.value,
      NOTIFICATION_BACKGROUND_COLOR: backgroundColor?.value
    };
  }

  ImageProvider? get bigPictureImage {
    if (bigPicture?.isEmpty ?? true) return null;
    return BitmapUtils().getFromMediaPath(bigPicture!);
  }

  ImageProvider? get largeIconImage {
    if (largeIcon?.isEmpty ?? true) return null;
    return BitmapUtils().getFromMediaPath(largeIcon!);
  }

  String? get bigPicturePath {
    if (bigPicture?.isEmpty ?? true) return null;
    return BitmapUtils().cleanMediaPath(bigPicture!);
  }

  String? get largeIconPath {
    if (largeIcon?.isEmpty ?? true) return null;
    return BitmapUtils().cleanMediaPath(largeIcon!);
  }

  String? get titleWithoutHtml => HtmlUtils.removeAllHtmlTags(title)!;

  String? get bodyWithoutHtml => HtmlUtils.removeAllHtmlTags(body)!;

  @override
  void validate() {
    assert(!AssertUtils.isNullOrEmptyOrInvalid(id, int));
    assert(!AssertUtils.isNullOrEmptyOrInvalid(channelKey, String));
  }
}
