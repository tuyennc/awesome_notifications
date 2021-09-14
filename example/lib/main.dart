import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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

  /// Use this method to detect when a new notification or a schedule is created
  static Future <void> onCreatedNotificationMethod(ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg: 'Notification created on ${receivedNotification.createdLifeCycle.toString().split('.').last}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: MyApp.mainColor,
        gravity: ToastGravity.CENTER
    );
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future <void> onDisplayedNotificationMethod(ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg: 'Notification displayed on ${receivedNotification.displayedLifeCycle.toString().split('.').last}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: MyApp.mainColor,
        gravity: ToastGravity.CENTER
    );
  }

  /// Use this method to detect if the user dismissed a notification
  static Future <void> onDismissedNotificationMethod(ReceivedAction receivedAction) async {
    Fluttertoast.showToast(
        msg: 'Notification dismissed on ${receivedAction.dismissedLifeCycle.toString().split('.').last}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        gravity: ToastGravity.CENTER
    );
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future <void> onActionNotificationMethod(ReceivedAction receivedAction) async {
    /// This replaces actionStream

    switch(receivedAction.notificationActionType){

    // Default Notification behavior, that brings the app to foreground
      case NotificationActionType.BringToForeground:
        Fluttertoast.showToast(
            msg: 'Action received on ${receivedAction.actionLifeCycle.toString().split('.').last}',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: MyApp.mainColor,
            gravity: ToastGravity.CENTER
        );
        break;

    // Do not bring the app to foreground and do not work with app killed
      case NotificationActionType.KeepOnTopAction:
        break;

    // Receive silent notification actions without bring the app to foreground
      case NotificationActionType.SilentAction: // Runs on main thread
        Fluttertoast.showToast(
            msg:
              ( receivedAction.buttonKeyInput.isEmpty ) ?
                'Silent Notification Received on ${receivedAction.actionLifeCycle.toString().split('.').last}' :
                'MSG: ${receivedAction.buttonKeyInput}',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: MyApp.mainColor,
            gravity: ToastGravity.CENTER
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

    requestPermissionToSendNotifications();

    AwesomeNotifications().setListeners(
        onCreatedNotificationMethod: MyApp.onCreatedNotificationMethod,
        onDismissedNotificationMethod: MyApp.onDismissedNotificationMethod,
        onActionNotificationMethod: MyApp.onActionNotificationMethod,
        onDisplayedNotificationMethod: MyApp.onDisplayedNotificationMethod
    );
    super.initState();
  }

  int createUniqueID(int maxValue){
    Random random = new Random();
    return random.nextInt(maxValue);
  }

  Future<bool> requestPermissionToSendNotifications() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if(!isAllowed){
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Allow Notifications'),
            content: Text('Our app would like to send you notifications'),
            actions: [
              TextButton(
                  onPressed: () async {
                    isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
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

  void createSimpleNotification(){
    requestPermissionToSendNotifications()
        .then((isAllowed) =>
            !isAllowed ? false :
            AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: createUniqueID(AwesomeNotifications.maxID),
                    channelKey: 'simple_channel',
                    title: 'Simple Notification',
                    body: 'This is a simple notification'
                )
            ));
  }

  void createBigPictureNotification(){
    requestPermissionToSendNotifications()
        .then((isAllowed){
          if(isAllowed){

            String randomBigPicture = 'https://picsum.photos/id/${createUniqueID(1000)}/200/300';
            String randomLargeIcon = 'https://picsum.photos/id/${createUniqueID(1000)}/50';

            AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: createUniqueID(AwesomeNotifications.maxID),
                    channelKey: 'simple_channel',
                    title: 'Big Picture Notification',
                    body: 'This is a notification with a big picture',
                    bigPicture: randomBigPicture,
                    largeIcon: randomLargeIcon,
                    notificationLayout: NotificationLayout.BigPicture
                )
            );
          }
        });
  }

  void createSilentNotification(){
    requestPermissionToSendNotifications()
        .then((isAllowed) =>
            !isAllowed ? false :
            AwesomeNotifications().createNotification(
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
            ));
  }

  void createSilentBackgroundNotification(){
    requestPermissionToSendNotifications()
        .then((isAllowed) =>
            !isAllowed ? false :
            AwesomeNotifications().createNotification(
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
            ));
  }

  void dismissAllNotifications(){
    AwesomeNotifications().dismissAllNotifications();
  }

  void cancelAllNotifications(){
    AwesomeNotifications().cancelAll();
  }

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
            onPressed: () => createSimpleNotification(),
            child: Text('Create simple notification'),
          ),
          ElevatedButton(
            onPressed: () => createBigPictureNotification(),
            child: Text('Create notification with big picture'),
          ),
          ElevatedButton(
            onPressed: () => createSilentNotification(),
            child: Text('Create silent notification'),
          ),
          ElevatedButton(
            onPressed: () => createSilentBackgroundNotification(),
            child: Text('Create silent background notification'),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => dismissAllNotifications(),
            style: ElevatedButton.styleFrom(primary: Colors.red, textStyle: TextStyle(color: Colors.white)),
            child: Text('Dismiss all notifications from statusbar'),
          ),
          ElevatedButton(
            onPressed: () => cancelAllNotifications(),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ActionReceived:'),
              Text('$receivedAction'),
            ],
          ),
        )
      ),
    );
  }
}