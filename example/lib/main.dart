import 'dart:io';

import 'package:awesome_notifications_example/utils/notification_util.dart';
import 'package:flutter/material.dart' hide DateUtils;
//import 'package:flutter/material.dart' as Material show DateUtils;

import 'package:awesome_notifications_example/routes.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/media_player_central.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white),
      NotificationChannel(
          channelKey: 'badge_channel',
          channelName: 'Badge indicator notifications',
          channelDescription: 'Notification channel to activate badge indicator',
          channelShowBadge: true,
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.yellow),
      NotificationChannel(
          channelKey: 'ringtone_channel',
          channelName: 'Ringtone Channel',
          channelDescription: 'Channel with default ringtone',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          defaultRingtoneType: DefaultRingtoneType.Ringtone),
      NotificationChannel(
          channelKey: 'updated_channel',
          channelName: 'Channel to update',
          channelDescription: 'Notifications with not updated channel',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white),
      NotificationChannel(
          channelKey: 'low_intensity',
          channelName: 'Low intensity notifications',
          channelDescription:
              'Notification channel for notifications with low intensity',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          vibrationPattern: lowVibrationPattern),
      NotificationChannel(
          channelKey: 'medium_intensity',
          channelName: 'Medium intensity notifications',
          channelDescription:
              'Notification channel for notifications with medium intensity',
          defaultColor: Colors.yellow,
          ledColor: Colors.yellow,
          vibrationPattern: mediumVibrationPattern),
      NotificationChannel(
          channelKey: 'high_intensity',
          channelName: 'High intensity notifications',
          channelDescription:
              'Notification channel for notifications with high intensity',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          vibrationPattern: highVibrationPattern),
      NotificationChannel(
          channelKey: "private_channel",
          channelName: "Privates notification channel",
          channelDescription: "Privates notification from lock screen",
          playSound: true,
          defaultColor: Colors.red,
          ledColor: Colors.red,
          vibrationPattern: lowVibrationPattern,
          defaultPrivacy: NotificationPrivacy.Private),
      NotificationChannel(
          icon: 'resource://drawable/res_power_ranger_thunder',
          channelKey: "custom_sound",
          channelName: "Custom sound notifications",
          channelDescription: "Notifications with custom sound",
          playSound: true,
          soundSource: 'resource://raw/res_morph_power_rangers',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          vibrationPattern: lowVibrationPattern),
      NotificationChannel(
          channelKey: "silenced",
          channelName: "Silenced notifications",
          channelDescription: "The most quiet notifications",
          playSound: false,
          enableVibration: false,
          enableLights: false),
      NotificationChannel(
          icon: 'resource://drawable/res_media_icon',
          channelKey: 'media_player',
          channelName: 'Media player controller',
          channelDescription: 'Media player controller',
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: false,
          enableLights: false,
          playSound: false,
          locked: true),
      NotificationChannel(
          channelKey: 'big_picture',
          channelName: 'Big pictures',
          channelDescription: 'Notifications with big and beautiful images',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
          vibrationPattern: lowVibrationPattern),
      NotificationChannel(
          channelKey: 'big_text',
          channelName: 'Big text notifications',
          channelDescription: 'Notifications with a expandable body text',
          defaultColor: Colors.blueGrey,
          ledColor: Colors.blueGrey,
          vibrationPattern: lowVibrationPattern),
      NotificationChannel(
          channelKey: 'inbox',
          channelName: 'Inbox notifications',
          channelDescription: 'Notifications with inbox layout',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
          vibrationPattern: mediumVibrationPattern),
      NotificationChannel(
          channelKey: 'scheduled',
          channelName: 'Scheduled notifications',
          channelDescription: 'Notifications with schedule functionality',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
          vibrationPattern: lowVibrationPattern,
          importance: NotificationImportance.High,
          defaultRingtoneType: DefaultRingtoneType.Alarm),
      NotificationChannel(
          icon: 'resource://drawable/res_download_icon',
          channelKey: 'progress_bar',
          channelName: 'Progress bar notifications',
          channelDescription: 'Notifications with a progress bar layout',
          defaultColor: Colors.deepPurple,
          ledColor: Colors.deepPurple,
          vibrationPattern: lowVibrationPattern,
          onlyAlertOnce: true),
      NotificationChannel(
          channelKey: 'grouped',
          channelName: 'Grouped notifications',
          channelDescription: 'Notifications with group functionality',
          groupKey: 'grouped',
          groupSort: GroupSort.Desc,
          groupAlertBehavior: GroupAlertBehavior.Children,
          defaultColor: Colors.lightGreen,
          ledColor: Colors.lightGreen,
          vibrationPattern: lowVibrationPattern,
          importance: NotificationImportance.High)
    ],
    debug: true
  );


  /// Class created to simulate an media player, there is no correlation with
  /// notifications at all
  MediaPlayerCentral.addAll([
    MediaModel(
        diskImagePath: 'asset://assets/images/rock-disc.jpg',
        colorCaptureSize: Size(788, 800),
        bandName: 'Bright Sharp',
        trackName: 'Champagne Supernova',
        trackSize: Duration(minutes: 4, seconds: 21)),
    MediaModel(
        diskImagePath: 'asset://assets/images/classic-disc.jpg',
        colorCaptureSize: Size(500, 500),
        bandName: 'Best of Mozart',
        trackName: 'Allegro',
        trackSize: Duration(minutes: 7, seconds: 41)),
    MediaModel(
        diskImagePath: 'asset://assets/images/remix-disc.jpg',
        colorCaptureSize: Size(500, 500),
        bandName: 'Dj Allucard',
        trackName: '21st Century',
        trackSize: Duration(minutes: 4, seconds: 59)),
    MediaModel(
        diskImagePath: 'asset://assets/images/dj-disc.jpg',
        colorCaptureSize: Size(500, 500),
        bandName: 'Dj Brainiak',
        trackName: 'Speed of light',
        trackSize: Duration(minutes: 4, seconds: 59)),
    MediaModel(
        diskImagePath: 'asset://assets/images/80s-disc.jpg',
        colorCaptureSize: Size(500, 500),
        bandName: 'Back to the 80\'s',
        trackName: 'Disco revenge',
        trackSize: Duration(minutes: 4, seconds: 59)),
    MediaModel(
        diskImagePath: 'asset://assets/images/old-disc.jpg',
        colorCaptureSize: Size(500, 500),
        bandName: 'PeacefulMind',
        trackName: 'Never look at back',
        trackSize: Duration(minutes: 4, seconds: 59)),
  ]);

  runApp(App());
}

class App extends StatefulWidget {
  App();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String name = 'Awesome Notifications - Example App';
  static Color mainColor = Color(0xFF9D50DD);

  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onCreatedNotificationMethod(ReceivedNotification receivedNotification) async {
    String? createdSourceText =
        AssertUtils.toSimpleEnumString(receivedNotification.createdSource);

    Fluttertoast.showToast(
        msg: '$createdSourceText notification created',
        textColor: Colors.white,
        backgroundColor: Colors.green);
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onDisplayedNotificationMethod(ReceivedNotification receivedNotification) async {
    String? createdSourceText =
        AssertUtils.toSimpleEnumString(receivedNotification.createdSource);

    Fluttertoast.showToast(
        msg: '$createdSourceText notification displayed',
        textColor: Colors.white,
        backgroundColor: Colors.blueAccent);
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissedNotificationMethod(ReceivedAction receivedAction) async {
    String? dismissedSourceText = AssertUtils.toSimpleEnumString(
        receivedAction.dismissedLifeCycle);

    Fluttertoast.showToast(
        msg: 'Notification dismissed on $dismissedSourceText',
        textColor: Colors.white,
        backgroundColor: Colors.red);
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionNotificationMethod(ReceivedAction receivedAction) async {

    String targetPage =
        receivedAction.channelKey == 'media_player' ?
              PAGE_MEDIA_DETAILS : PAGE_NOTIFICATION_DETAILS;

    // If the user sent a message through an notification, just
    // display the text as a example
    if (!StringUtils.isNullOrEmpty(receivedAction.buttonKeyInput)) {
      processInputTextReceived(receivedAction);
      return;
    }

    switch(receivedAction.notificationActionType){

      // Go to default redirect page behavior
      case NotificationActionType.BringToForeground:
        Fluttertoast.showToast(
            msg: 'Action received',
            textColor: Colors.black,
            backgroundColor: Colors.yellow);
        break;

      // just do an remote control for media player without redirect the page
      case NotificationActionType.KeepOnTopAction:
        if (receivedAction.channelKey == 'media_player') {
          processMediaControls(receivedAction);
          return;
        }
        break;

      // receive silent request
      case NotificationActionType.SilentAction:
      case NotificationActionType.SilentBackgroundAction:

        // Prints the action received on console for debug
        print('"ReceivedAction": ${receivedAction.toString()}');

        // SilentBackgroundAction does not accept UI elements
        if(receivedAction.notificationActionType == NotificationActionType.SilentAction){
          // Show some visual on screen to the user
          Fluttertoast.showToast(
              msg: 'Silent action received',
              backgroundColor: Colors.blueAccent,
              textColor: Colors.white,
              fontSize: 16
          );

          // Give time to toast shows if the app is terminated
          sleep(Duration(seconds:2));
        }
        return;

      // disabled actions never reach this point, they die
      // at native level.
      case NotificationActionType.DisabledAction:
      default:
        break;
    }

    // Avoid to open the notification details page over another details page already opened
    App.navigatorKey.currentState?.pushNamedAndRemoveUntil(targetPage,
            (route) => (route.settings.name != targetPage) || route.isFirst,
        arguments: receivedAction);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {

  @override
  void dispose() {
    MediaPlayerCentral.stop();
    MediaPlayerCentral.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The navigator key is necessary to allow to navigate through static classes
      navigatorKey: App.navigatorKey,

      // These routes are declared in a separated file called routes.dart
      initialRoute: PAGE_HOME,
      routes: materialRoutes,

      title: App.name,
      color: App.mainColor,

      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),

      theme: ThemeData(
        brightness: Brightness.light,

        primaryColor: App.mainColor,
        accentColor: Colors.blueGrey,
        canvasColor: Colors.white,
        focusColor: Colors.blueAccent,
        disabledColor: Colors.grey,

        backgroundColor: Colors.blueGrey.shade400,

        appBarTheme: AppBarTheme(
            brightness: Brightness.dark,
            color: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: App.mainColor,
            ),
            textTheme: TextTheme(
              headline6: TextStyle(color: App.mainColor, fontSize: 18),
            )),

        fontFamily: 'Robot',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: 64.0, height: 1.5, fontWeight: FontWeight.w500),
          headline2: TextStyle(
              fontSize: 52.0, height: 1.5, fontWeight: FontWeight.w500),
          headline3: TextStyle(
              fontSize: 48.0, height: 1.5, fontWeight: FontWeight.w500),
          headline4: TextStyle(
              fontSize: 32.0, height: 1.5, fontWeight: FontWeight.w500),
          headline5: TextStyle(
              fontSize: 28.0, height: 1.5, fontWeight: FontWeight.w500),
          headline6: TextStyle(
              fontSize: 22.0, height: 1.5, fontWeight: FontWeight.w500),
          subtitle1:
              TextStyle(fontSize: 18.0, height: 1.5, color: Colors.black54),
          subtitle2:
              TextStyle(fontSize: 12.0, height: 1.5, color: Colors.black54),
          button: TextStyle(fontSize: 16.0, height: 1.5, color: Colors.black54),
          bodyText1: TextStyle(fontSize: 16.0, height: 1.5),
          bodyText2: TextStyle(fontSize: 16.0, height: 1.5),
        ),

        buttonTheme: ButtonThemeData(
          buttonColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5))),
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          textTheme: ButtonTextTheme.accent,
        ),
      ),
    );
  }
}
