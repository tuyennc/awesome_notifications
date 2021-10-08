import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/android_foreground_service.dart';

void main() {
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
          channelKey: 'simple_channel',
          channelName: 'Simple Example Channel',
          channelDescription: 'This is a simple example channel with badge counter activated',
          channelShowBadge: true,
          importance: NotificationImportance.Max,
          defaultColor: MyApp.mainColor
      ),
      NotificationChannel(
          channelKey: 'chats',
          channelName: 'Chat groups',
          channelDescription: 'This is a simple example channel of a chat group',
          channelShowBadge: true,
          importance: NotificationImportance.Max,
          defaultColor: MyApp.mainColor
      ),
      NotificationChannel(
          channelKey: 'foreground_service',
          channelName: 'Background Service',
          channelDescription: 'This channel is used to execute foreground services',
          importance: NotificationImportance.High,
          locked: true,
          playSound: false,
          defaultPrivacy: NotificationPrivacy.Public
      ),
      NotificationChannel(
          channelKey: 'background_channel',
          channelName: 'Background Channel',
          channelDescription: 'This channel is silent and do not increment badge counter',
          channelShowBadge: false,
          importance: NotificationImportance.Max,
          defaultColor: MyApp.mainColor
      )
    ],
    debug: true
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

  static String _toSimpleEnum(NotificationLifeCycle lifeCycle) => lifeCycle.toString().split('.').last;

  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg: 'Notification created on ${_toSimpleEnum(receivedNotification.createdLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: MyApp.mainColor,
        gravity: ToastGravity.BOTTOM
    );
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg: 'Notification displayed on ${_toSimpleEnum(receivedNotification.displayedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: MyApp.mainColor,
        gravity: ToastGravity.BOTTOM
    );
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    Fluttertoast.showToast(
        msg: 'Notification dismissed on ${_toSimpleEnum(receivedAction.dismissedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        gravity: ToastGravity.BOTTOM
    );
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    /// This replaces actionStream

    switch(receivedAction.notificationActionType){

    // Default Notification behavior, that brings the app to foreground
      case NotificationActionType.BringToForeground:
        Fluttertoast.showToast(
            msg: 'Action received on ${_toSimpleEnum(receivedAction.actionLifeCycle!)}',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: MyApp.mainColor,
            gravity: ToastGravity.BOTTOM
        );
        break;

    // Do not bring the app to foreground and do not work with app killed
      case NotificationActionType.KeepOnTopAction:
        break;

    // Receive silent notification actions without bring the app to foreground
      case NotificationActionType.SilentAction: // Runs on main thread

        if(
          receivedAction.channelKey == 'chats' &&
          !(receivedAction.groupKey?.isEmpty ?? true) &&
          receivedAction.actionKey == 'REPLY'
        ){
            await NotificationUtils.createMessagingNotification(
              channelKey: 'chats',
              groupKey: receivedAction.groupKey!,
              chatName: 'Jhonny\'s Group',
              username: 'You',
              largeIcon: 'asset://assets/images/remix-disc.jpg',
              message: receivedAction.actionInput,
              checkPermission: false
            );
        }

        Fluttertoast.showToast(
            msg:
              ( receivedAction.actionInput.isEmpty ) ?
                'Silent Notification Received on ${_toSimpleEnum(receivedAction.actionLifeCycle!)}' :
                'MSG: ${receivedAction.actionInput}',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.lightBlue,
            gravity: ToastGravity.BOTTOM
        );
        debugPrint('$receivedAction');
        return;

    // Runs on background thread for heavier tasks (without UI)
      case NotificationActionType.SilentBackgroundAction:
        debugPrint('$receivedAction');
        return;

    // disabled actions never reach this point, they die
    // at native level.
      case NotificationActionType.DisabledAction:
      default:
        break;
    }

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/notification-page',
            (route) => (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      // The navigator key is necessary to allow to navigate through static methods
      navigatorKey: MyApp.navigatorKey,

      title: MyApp.name,
      color: MyApp.mainColor,

      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) =>
                MyHomePage(title: MyApp.name)
            );

          case '/notification-page':
            return MaterialPageRoute(builder: (context) {
              final ReceivedAction receivedAction = settings
                  .arguments as ReceivedAction;
              return MyNotificationPage(receivedAction: receivedAction);
            });

          default:
            assert(false, 'Page ${settings.name} not found');
            return null;
        }
      },

      theme: ThemeData(
          primarySwatch: Colors.deepPurple
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();

    // Necessary to request the user permission to send notifications
    NotificationUtils.requestPermissionToSendNotifications();

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod:         MyApp.onActionReceivedMethod,
        onNotificationCreatedMethod:    MyApp.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  MyApp.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  MyApp.onDismissActionReceivedMethod
    );
  }

  int _messageIncrement = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: <Widget>[
          ElevatedButton(
            onPressed: () => NotificationUtils.createSimpleNotification(),
            child: Text('Create simple notification'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.createBigPictureNotification(),
            child: Text('Create notification with big picture'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.createBigTextNotification(),
            child: Text('Create notification with big text'),
          ),
          ElevatedButton(
            onPressed: () =>
              _messageIncrement++ % 4 < 2 ?
                NotificationUtils.createMessagingNotification(
                    channelKey: 'chats',
                    groupKey: 'jhonny_group',
                    chatName: 'Jhonny\'s Group',
                    username: 'Jhonny',
                    largeIcon: 'asset://assets/images/80s-disc.jpg',
                    message: 'Jhonny\'s message $_messageIncrement',
                ):
                NotificationUtils.createMessagingNotification(
                    channelKey: 'chats',
                    groupKey: 'jhonny_group',
                    chatName: 'Michael\'s Group',
                    username: 'Michael',
                  largeIcon: 'asset://assets/images/dj-disc.jpg',
                    message: 'Michael\'s message $_messageIncrement',
                ),
            child: Text('Create messaging notification'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.createSilentNotification(),
            child: Text('Create silent notification'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.createSilentBackgroundNotification(),
            child: Text('Create silent background notification'),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => NotificationUtils.createScheduledNotification(),
            child: Text('Create single scheduled notification'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.createScheduleRepeatedNotification(),
            child: Text('Create repeated scheduled notification'),
          ),
          SizedBox(height: 40),

          /* ******************************************************************** */

          ElevatedButton(
              child: Text('Start foreground service'),
              onPressed: () => NotificationUtils.startForegroundService()),
          ElevatedButton(
              child: Text('Stop foreground service'),
              onPressed: () => NotificationUtils.stopForegroundService()),
          SizedBox(height: 40),

          /* ******************************************************************** */

          ElevatedButton(
            onPressed: () => NotificationUtils.dismissAllNotifications(),
            style: ElevatedButton.styleFrom(primary: Colors.red, textStyle: TextStyle(color: Colors.white)),
            child: Text('Dismiss all notifications from statusbar'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.dismissNotificationsByChannelKey('simple_channel'),
            style: ElevatedButton.styleFrom(primary: Colors.red, textStyle: TextStyle(color: Colors.white)),
            child: Text('Dismiss all notifications with same channel key'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.dismissNotificationsByGroupKey('jhonny_group'),
            style: ElevatedButton.styleFrom(primary: Colors.red, textStyle: TextStyle(color: Colors.white)),
            child: Text('Dismiss all notifications with same group key'),
          ),
          ElevatedButton(
            onPressed: () => NotificationUtils.cancelAllNotifications(),
            style: ElevatedButton.styleFrom(primary: Colors.red, textStyle: TextStyle(color: Colors.white)),
            child: Text('Cancel all notifications'),
          ),
        ],
      ) // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MyNotificationPage extends StatelessWidget {

  final ReceivedAction receivedAction;

  MyNotificationPage({required this.receivedAction, Key? key}) : super(key: key){
    // Decrement the badge counter it the user enters on Notification Page
    // Set it to zero to remove the badge counter
    AwesomeNotifications().getGlobalBadgeCounter().then(
        (badgeCounter) => AwesomeNotifications().setGlobalBadgeCounter(badgeCounter - 1)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Page'),
        brightness: Brightness.dark,
      ),
      body: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            Text('ActionReceived:'),
            Text('$receivedAction'),
          ],
      ),
    );
  }
}

class NotificationUtils {

  static int createUniqueID(int maxValue){
    Random random = new Random();
    return random.nextInt(maxValue);
  }

  static Future<bool> requestPermissionToSendNotifications() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if(!isAllowed){
      showDialog(
          context: MyApp.navigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: Text('Allow Notifications'),
            content: Text('Our app would like to send you notifications'),
            actions: [
              TextButton(
                onPressed: () async {
                  isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
                  Navigator.pop(context);
                },
                child: Text(
                  'Allow',
                  style: TextStyle(color: MyApp.mainColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                  onPressed: (){ Navigator.pop(context); },
                  child: Text(
                    'Dont\'t Allow',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  )
              )
            ],
          )
      );
    }
    return isAllowed;
  }

  static Future<void> createSimpleNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: createUniqueID(AwesomeNotifications.maxID),
              channelKey: 'simple_channel',
              title: 'Simple Notification',
              body: 'This is a simple notification'
          )
      );
  }

  static Future<void> createMessagingNotification({
    required String channelKey,
    required String groupKey,
    required String chatName,
    required String username,
    required String message,
    String? largeIcon,
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
          content:
          NotificationContent(
              id: createUniqueID(AwesomeNotifications.maxID),
              groupKey: groupKey,
              channelKey: channelKey,
              summary: chatName,
              title: username,
              body: message,
              largeIcon: largeIcon,
              notificationLayout: NotificationLayout.Messaging
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'REPLY',
              label: 'Reply',
              requireInputText: true,
              autoDismissible: false,
              notificationActionType: NotificationActionType.SilentAction,
            ),
            NotificationActionButton(
              key: 'READ',
              label: 'Mark as Read',
              autoDismissible: true,
              notificationActionType: NotificationActionType.SilentAction,
            )
          ]
      );
  }

  static Future<void> createBigPictureNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: createUniqueID(AwesomeNotifications.maxID),
                channelKey: 'simple_channel',
                title: 'Big Picture Notification',
                body: 'This is a notification with a big picture',
                bigPicture: 'asset://assets/images/balloons-in-sky.jpg',
                largeIcon: 'asset://assets/images/80s-disc.jpg',
                notificationLayout: NotificationLayout.BigPicture
            )
        );
  }

  static Future<void> createBigTextNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: createUniqueID(AwesomeNotifications.maxID),
                channelKey: 'simple_channel',
                title: '<b>Big Picture</b> Notification',
                body: '<br>Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
                    'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.<br><br>'
                    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                    'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                    'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
                    'pariatur',
                notificationLayout: NotificationLayout.BigText
            )
        );
  }

  static Future<void> createSilentNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: createUniqueID(AwesomeNotifications.maxID),
            channelKey: 'background_channel',
            title: 'Silent Notification',
            body: 'This is a silent notification to receive notification without bring the app to foreground',
          ),
          actionButtons: [
            NotificationActionButton(
                key: 'DISMISS',
                label: 'Cancel',
                notificationActionType: NotificationActionType.DisabledAction,
                autoDismissible: true
            ),
            NotificationActionButton(
              key: 'EXECUTE',
              label: 'Execute Now',
              notificationActionType: NotificationActionType.SilentAction,
            ),
            NotificationActionButton(
              key: 'REPLY',
              label: 'Reply',
              requireInputText: true,
              notificationActionType: NotificationActionType.SilentAction,
            ),
          ]
      );
  }

  static Future<void> createSilentBackgroundNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed)
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: createUniqueID(AwesomeNotifications.maxID),
              channelKey: 'background_channel',
              title: 'Silent Notification',
              body: 'This is a silent notification to run on background without UI'
          ),
          actionButtons: [
            NotificationActionButton(
                key: 'CANCEL',
                label: 'Cancel',
                notificationActionType: NotificationActionType.DisabledAction,
                autoDismissible: true
            ),
            NotificationActionButton(
              key: 'EXECUTE',
              label: 'Execute',
              notificationActionType: NotificationActionType.SilentBackgroundAction,
            ),
          ]
      );
  }

  static Future<void> createScheduledNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed) {
      int id = createUniqueID(AwesomeNotifications.maxID);
      DateTime targetDate = DateTime.now();
      targetDate = targetDate.add(Duration(minutes: 5));

      await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: id,
              channelKey: 'simple_channel',
              title: 'Notification Scheduled ($id)',
              body: 'This notification was scheduled to be delivered at ${targetDate
                  .toLocal().toIso8601String()}'
          ),
          schedule: NotificationCalendar.fromDate(
              date: targetDate
          )
      );
    }
  }

  static Future<void> createScheduleRepeatedNotification({
    bool checkPermission = true
  }) async {
    bool isAllowed = !checkPermission || await requestPermissionToSendNotifications();
    if (isAllowed){
      int id = createUniqueID(AwesomeNotifications.maxID);
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: id,
              channelKey: 'simple_channel',
              title: 'Repeated Schedule ($id)',
              body: 'This notification was scheduled to repeat every 10 seconds'
          ),
          schedule: NotificationInterval(
              interval: 10,
              repeats: true
          )
      );
    }
  }

  static Future<void> startForegroundService() async {
    AndroidForegroundService.startForeground(
        content: NotificationContent(
          id: 42,
          body: 'Service is running!',
          title: 'Android Foreground Service',
          channelKey: 'foreground_service',
          bigPicture: 'asset://assets/images/android-bg-worker.jpg',
          notificationLayout: NotificationLayout.BigPicture,
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'SHOW_SERVICE_DETAILS',
              label: 'Show details'
          )
        ]
    );
  }

  static Future<void> stopForegroundService() async {
    AndroidForegroundService.stopForeground();
  }

  static Future<void> dismissAllNotifications() async {
    await AwesomeNotifications().dismissAllNotifications();
  }

  static Future<void> dismissNotificationsByChannelKey(String channelKey) async {
    await AwesomeNotifications().dismissNotificationsByChannelKey(channelKey);
  }

  static Future<void> dismissNotificationsByGroupKey(String groupKey) async {
    await AwesomeNotifications().dismissNotificationsByGroupKey(groupKey);
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}