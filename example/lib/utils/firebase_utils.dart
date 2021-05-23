import 'dart:convert';
import 'dart:math';
import'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_example/utils/notification_util.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// TO AVOID CONFLICT WITH MATERIAL DATE UTILS CLASS
import 'package:awesome_notifications/awesome_notifications.dart'
    hide DateUtils;
import 'package:awesome_notifications/awesome_notifications.dart' as Utils
    show DateUtils;

// Platform messages are asynchronous, so we initialize in an async method.
class FirebaseUtils {

  static Future<void> loadFirebaseCore() async {
    await Firebase.initializeApp();
  }

  static Future<String> initializeFirebaseService(BuildContext context) async {

    return FirebaseMessaging.instance.getToken(
      // https://stackoverflow.com/questions/54996206/firebase-cloud-messaging-where-to-find-public-vapid-key
      vapidKey: '',
    ).then((firebaseAppToken){

      if (StringUtils.isNullOrEmpty(firebaseAppToken,
          considerWhiteSpaceAsEmpty: true)) return '';

      print('Firebase token: $firebaseAppToken');

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get any messages which caused the application to open from
      // a terminated state.
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? initialMessage){
        // If the message also contains a data property with a "type" of "chat",
        // navigate to a chat screen
        if (initialMessage != null) {
          receivedActionFromFirebase(context, initialMessage);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        PushNotification? pushNotification =
          await awesomeNotificationFromFirebaseRemoteMessage(
              message,
              // Android default FCM notification is different for Android and iOS
              // On iOS is displayed a default notification, but not on Android.
              acceptRemoteNotificationContent: Platform.isAndroid ? true : false
          );
        if(pushNotification != null){

          AwesomeNotifications().createNotification(
              content: pushNotification.content!,
              schedule: pushNotification.schedule,
              actionButtons: pushNotification.actionButtons);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        receivedActionFromFirebase(context, message);
      });

      return firebaseAppToken ?? '';
    });
  }

  static Future<void> receivedActionFromFirebase(BuildContext context, RemoteMessage message) async {
    PushNotification? pushNotification = await awesomeNotificationFromFirebaseRemoteMessage(message, acceptRemoteNotificationContent: true);

    if (pushNotification != null) {
      ReceivedAction receivedAction = ReceivedAction.fromNotificationContent(pushNotification.content!);
      processDefaultActionReceived(context, receivedAction);
    }
  }

  static Future<PushNotification?> awesomeNotificationFromFirebaseRemoteMessage(RemoteMessage message, {bool acceptRemoteNotificationContent = false}){

    print('Handling a firebase message: ${message.messageId}');

    if(
        !StringUtils.isNullOrEmpty(message.notification?.title, considerWhiteSpaceAsEmpty: true) ||
        !StringUtils.isNullOrEmpty(message.notification?.body, considerWhiteSpaceAsEmpty: true)
    ){

      if(!acceptRemoteNotificationContent)
        return Future.value(null);

      print('message also contained a notification: ${message.notification}');

      Map<String, dynamic> dataMap = jsonDecode(message.data[NOTIFICATION_CONTENT]);

      String? imageUrl;
      imageUrl ??= dataMap[NOTIFICATION_BIG_PICTURE];
      imageUrl ??= message.notification!.android?.imageUrl;
      imageUrl ??= message.notification!.apple?.imageUrl;

      String now = Utils.DateUtils.getUtcTextDate();

      Map<String, dynamic> pushNotificationAdapter = {
        NOTIFICATION_CONTENT: {
          NOTIFICATION_CHANNEL_KEY:
          dataMap[NOTIFICATION_CHANNEL_KEY] ??
              'basic_channel',
          NOTIFICATION_ID:
          message.messageId ??
              dataMap[NOTIFICATION_ID] ??
              Random().nextInt(2147483647),
          NOTIFICATION_TITLE:
          dataMap[NOTIFICATION_TITLE] ??
              message.notification?.title,
          NOTIFICATION_BODY:
          dataMap[NOTIFICATION_BODY] ??
              message.notification?.body ,
          NOTIFICATION_LAYOUT:
              StringUtils.isNullOrEmpty(imageUrl) ? 'Default' : 'BigPicture',
          NOTIFICATION_BIG_PICTURE:
              imageUrl,
          NOTIFICATION_LARGE_ICON:
              dataMap[NOTIFICATION_LARGE_ICON],
          NOTIFICATION_PAYLOAD:
              dataMap[NOTIFICATION_PAYLOAD],
          NOTIFICATION_CREATED_DATE:
              dataMap[NOTIFICATION_CREATED_DATE] ?? now,
          NOTIFICATION_CREATED_LIFECYCLE:
              dataMap[NOTIFICATION_CREATED_LIFECYCLE] ?? NotificationLifeCycle.AppKilled,
          NOTIFICATION_DISPLAYED_DATE:
              dataMap[NOTIFICATION_DISPLAYED_DATE] ?? now,
          NOTIFICATION_DISPLAYED_LIFECYCLE:
              dataMap[NOTIFICATION_DISPLAYED_LIFECYCLE] ?? NotificationLifeCycle.AppKilled,
        }
      };

      return AwesomeNotifications().extractNotificationFromJsonData(pushNotificationAdapter);
    }
    else {
      return AwesomeNotifications().extractNotificationFromJsonData(message.data);
    }
  }

}

// DATA ONLY NOTIFICATIONS DOES NOT ALWAYS RUNS ON IOS WHILE THE APP IS IN BACKGROUND.
// FOR ANDROID IT WORKS ALL THE TIMES.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  PushNotification? pushNotification = await FirebaseUtils.awesomeNotificationFromFirebaseRemoteMessage(message);
  if(pushNotification != null){

    AwesomeNotifications().createNotification(
        content: pushNotification.content!,
        schedule: pushNotification.schedule,
        actionButtons: pushNotification.actionButtons);
  }
}