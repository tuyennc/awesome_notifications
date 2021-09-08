import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/isolates/isolate_main.dart';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html;
//import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:awesome_notifications/definitions.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:awesome_notifications/src/models/notification_button.dart';
import 'package:awesome_notifications/src/models/notification_channel.dart';
import 'package:awesome_notifications/src/models/notification_content.dart';
import 'package:awesome_notifications/src/models/notification_schedule.dart';
import 'package:awesome_notifications/src/models/received_models/notification_model.dart';
import 'package:awesome_notifications/src/models/received_models/received_action.dart';
import 'package:awesome_notifications/src/models/received_models/received_notification.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:awesome_notifications/src/utils/bitmap_utils.dart';
import 'package:awesome_notifications/src/utils/date_utils.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

class AwesomeNotifications {
  static String? rootNativePath;

  static String utcTimeZoneIdentifier = "UTC";
  static String localTimeZoneIdentifier = "UTC";

  ActionHandler? _actionHandler;
  ActionHandler? _dismissedHandler;
  NotificationHandler? _createdHandler;
  NotificationHandler? _displayedHandler;

  /// WEB SUPPORT METHODS *********************************************
/*
  static void registerWith(Registrar registrar) {
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    _handleWebMethodCall(call);
  }
*/
  /// STREAM CREATION METHODS *********************************************

  final BehaviorSubject<ReceivedNotification>
      // ignore: close_sinks
      _createdSubject = BehaviorSubject<ReceivedNotification>();

  final BehaviorSubject<ReceivedNotification>
      // ignore: close_sinks
      _displayedSubject = BehaviorSubject<ReceivedNotification>();

  final BehaviorSubject<ReceivedAction>
      // ignore: close_sinks
      _actionSubject = BehaviorSubject<ReceivedAction>();

  final BehaviorSubject<ReceivedAction>
      // ignore: close_sinks
      _dismissedSubject = BehaviorSubject<ReceivedAction>();

  /// STREAM METHODS *********************************************

  /// Stream to capture all created notifications
  @Deprecated('Use static methods instead, calling AwesomeNotifications().setListeners()')
  Stream<ReceivedNotification> get createdStream {
    return _createdSubject;
  }

  /// Stream to capture all notifications displayed on user's screen.
  @Deprecated('Use static methods instead, calling AwesomeNotifications().setListeners()')
  Stream<ReceivedNotification> get displayedStream {
    return _displayedSubject;
  }

  /// Stream to capture all notifications dismissed by the user.
  @Deprecated('Use static methods instead, calling AwesomeNotifications().setListeners()')
  Stream<ReceivedAction> get dismissedStream {
    return _dismissedSubject;
  }

  /// Stream to capture all actions (tap) over notifications
  @Deprecated('Use static methods instead, calling AwesomeNotifications().setListeners()')
  Stream<ReceivedAction> get actionStream {
    return _actionSubject;
  }

  /// SINK METHODS *********************************************

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get createdSink {
    return _createdSubject.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get displayedSink {
    return _displayedSubject.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get dismissedSink {
    return _dismissedSubject.sink;
  }

  /// Sink to dispose the stream, if you don't need it anymore.
  Sink get actionSink {
    return _actionSubject.sink;
  }

  /// CLOSE STREAM METHODS *********************************************

  /// Closes definitely all the streams.
  dispose() {
    _createdSubject.close();
    _displayedSubject.close();
    _dismissedSubject.close();
    _actionSubject.close();
  }

  /// SINGLETON METHODS *********************************************

  final MethodChannel _channel;

  factory AwesomeNotifications() => _instance;

  @visibleForTesting
  AwesomeNotifications.private(MethodChannel channel) : _channel = channel;

  static final AwesomeNotifications _instance =
      AwesomeNotifications.private(const MethodChannel(CHANNEL_FLUTTER_PLUGIN));

  /// INITIALIZING METHODS *********************************************

  /// Initializes the plugin, creating a default icon and the initial channels. Only needs
  /// to be called at main.dart once.
  /// OBS: [defaultIcon] needs to be a Resource media type
  /// OBS 2: [channels] are updated if they already exists
  Future<bool> initialize(
      String? defaultIcon,
      List<NotificationChannel> channels,
      {bool debug = false}) async {
    WidgetsFlutterBinding.ensureInitialized();

    _channel.setMethodCallHandler(_handleMethod);

    final CallbackHandle? dartCallbackReference = PluginUtilities.getCallbackHandle(dartIsolateMain);

    List<dynamic> serializedChannels = [];
    for (NotificationChannel channel in channels) {
      serializedChannels.add(channel.toMap());
    }

    String? defaultIconPath;
    if (kIsWeb) {
      // For web release
    } else {
      if (!AssertUtils.isNullOrEmptyOrInvalid(defaultIcon, String)) {
        // To set a icon on top of notification, is mandatory to user a native resource
        assert(
            BitmapUtils().getMediaSource(defaultIcon!) == MediaSource.Resource);
        defaultIconPath = defaultIcon;
      }
    }

    var result = await _channel.invokeMethod(CHANNEL_METHOD_INITIALIZE, {
      INITIALIZE_DEBUG_MODE: debug,
      INITIALIZE_DEFAULT_ICON: defaultIconPath,
      INITIALIZE_CHANNELS: serializedChannels,
      DART_BG_HANDLE: dartCallbackReference!.toRawHandle()
    });

    localTimeZoneIdentifier = await _channel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);
    utcTimeZoneIdentifier =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);

    return result;
  }

  /// NATIVE MEDIA METHODS *********************************************

  /// Decode a drawable resource bytes into a Uint8List to be used in Flutter widgets
  Future<Uint8List?> getDrawableData(String drawablePath) async {
    var result2 = await _channel.invokeMethod(
        CHANNEL_METHOD_GET_DRAWABLE_DATA, drawablePath);

    if (result2 == null) return null;

    return result2;
  }

  String silentBGActionTypeKey = AssertUtils.toSimpleEnumString(NotificationActionType.SilentBackgroundAction)!;

  Future<dynamic> _handleMethod(MethodCall call) async {
    Map<String, dynamic> arguments = (call.arguments as Map).cast<String, dynamic>();

    switch (call.method) {

      case CHANNEL_METHOD_NOTIFICATION_CREATED:
        _createdSubject.sink.add(ReceivedNotification().fromMap(arguments));
        return;

      case CHANNEL_METHOD_SILENT_ACTION:
        if(arguments[CHANNEL_METHOD_RECEIVED_ACTION][NOTIFICATION_ACTION_TYPE] == silentBGActionTypeKey) {
          compute(receiveSilentAction, arguments);
        } else {
          receiveSilentAction(arguments);
        }
        return;

      case CHANNEL_METHOD_NOTIFICATION_DISPLAYED:
        _displayedSubject.sink.add(ReceivedNotification().fromMap(arguments));
        return;

      case CHANNEL_METHOD_NOTIFICATION_DISMISSED:
        _dismissedSubject.sink
            .add(ReceivedAction().fromMap(arguments));
        return;

      case CHANNEL_METHOD_RECEIVED_ACTION:
        _actionSubject.sink
            .add(ReceivedAction().fromMap(arguments));
        return;

      case CHANNEL_METHOD_ISOLATE_CALLBACK:
        await channelMethodIsolateCallbackHandle(call);
        break;

      default:
        throw UnsupportedError('Unrecognized JSON message');
    }
  }

  StreamSubscription? _createdSubscription;
  StreamSubscription? _displayedSubscription;
  StreamSubscription? _actionSubscription;
  StreamSubscription? _dismissedSubscription;

  _startEventListeners(){

    // Ensures that there is at most one subscription
    _createdSubscription?.cancel();
    _displayedSubscription?.cancel();
    _actionSubscription?.cancel();
    _dismissedSubscription?.cancel();

    // Streams will be keept internally. They are deprecated to use outside.
    _createdSubscription = createdStream.listen((event) {
      if(_createdHandler != null) _createdHandler!(event);
    });
    _displayedSubscription = displayedStream.listen((event) {
      if(_displayedHandler != null) _displayedHandler!(event);
    });
    _actionSubscription = actionStream.listen((event) {
      if(_actionHandler != null) _actionHandler!(event);
    });
    _dismissedSubscription = dismissedStream.listen((event) {
      if(_dismissedHandler != null) _dismissedHandler!(event);
    });
  }

  static int get maxID => 2147483647;

  void _validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError(
          'The id field must be the limited to 32-bit size integer');
    }
  }

  /// LOCAL NOTIFICATION METHODS *********************************************

  /// Creates a new notification.
  /// If notification has no [body] or [title], it will only be created, but never displayed. (background notification)
  /// [schedule] and [actionButtons] are optional
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
  }) async {
    _validateId(content.id!);

    try {
      final bool wasCreated = await _channel.invokeMethod(
          CHANNEL_METHOD_CREATE_NOTIFICATION,
          NotificationModel(
                  content: content,
                  schedule: schedule,
                  actionButtons: actionButtons)
              .toMap());

      return wasCreated;
    } on PlatformException catch (error) {
      print(error);
    }
    return false;
  }

  Future<NotificationModel?> extractNotificationFromJsonData(
      Map<String, dynamic> mapData) async {
    try {
      if (mapData[NOTIFICATION_CONTENT].runtimeType == String)
        mapData[NOTIFICATION_CONTENT] =
            json.decode(mapData[NOTIFICATION_CONTENT]);

      if (mapData[NOTIFICATION_SCHEDULE].runtimeType == String)
        mapData[NOTIFICATION_SCHEDULE] =
            json.decode(mapData[NOTIFICATION_SCHEDULE]);

      if (mapData[NOTIFICATION_BUTTONS].runtimeType == String)
        mapData[NOTIFICATION_BUTTONS] =
            json.decode(mapData[NOTIFICATION_BUTTONS]);

      // Invalid Notification
      return NotificationModel().fromMap(mapData);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createNotificationFromJsonData(
      Map<String, dynamic> mapData) async {
    try {
      NotificationModel? pushNotification =
          await extractNotificationFromJsonData(mapData);
      if (pushNotification == null) {
        throw Exception('Notification map data is invalid');
      }

      return createNotification(
          content: pushNotification.content!,
          schedule: pushNotification.schedule,
          actionButtons: pushNotification.actionButtons);
    } catch (e) {
      return false;
    }
  }

  /// Check if the notifications are permitted
  Future<void> showNotificationConfigPage({String? channelKey}) async {
    await _channel.invokeMethod(CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE, {
      NOTIFICATION_CHANNEL_KEY: channelKey
    });
  }

  /// Check if the notifications are permitted
  Future<bool> isNotificationAllowed({String? channelKey}) async {
    final bool isAllowed =
        await _channel.invokeMethod(CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED, {
          NOTIFICATION_CHANNEL_KEY: channelKey
        });
    return isAllowed;
  }

  /// Prompts the user to enabled notifications
  Future<bool> requestPermissionToSendNotifications({String? channelKey}) async {
    final bool isAllowed =
        await _channel.invokeMethod(CHANNEL_METHOD_REQUEST_NOTIFICATIONS, {
          NOTIFICATION_CHANNEL_KEY: channelKey
        });
    return isAllowed;
  }

  /// List all active scheduled notifications.
  Future<List<NotificationModel>> listScheduledNotifications() async {
    List<NotificationModel> scheduledNotifications = [];
    List<Object>? returned =
        await _channel.invokeListMethod(CHANNEL_METHOD_LIST_ALL_SCHEDULES);
    if (returned != null) {
      for (Object object in returned) {
        if (object is Map) {
          try {
            NotificationModel pushNotification =
                NotificationModel().fromMap(Map<String, dynamic>.from(object))!;
            scheduledNotifications.add(pushNotification);
          } catch (e) {
            return [];
          }
        }
      }
    }
    return scheduledNotifications;
  }

  /// Set a new notification channel or updates if already exists
  /// [forceUpdate]: completely updates the channel on Android Oreo and above, but cancels all current notifications.
  Future<void> setChannel(
    NotificationChannel notificationChannel, {
    bool forceUpdate = false,
  }) async {
    Map<String, dynamic> parameters = notificationChannel.toMap();
    parameters.addAll({CHANNEL_FORCE_UPDATE: forceUpdate});

    await _channel.invokeMethod(
        CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL, parameters);
  }

  /// Remove a notification channel
  Future<bool> removeChannel(String channelKey) async {
    final bool wasRemoved = await _channel.invokeMethod(
        CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL, channelKey);
    return wasRemoved;
  }

  /// Get badge counter (on Android is 0 or 1)
  Future<void> setGlobalBadgeCounter(int? amount) async {
    if (amount == null) {
      return;
    }
    Map<String, dynamic> data = {
      NOTIFICATION_CHANNEL_SHOW_BADGE: amount
    };
    await _channel.invokeMethod(CHANNEL_METHOD_SET_BADGE_COUNT, data);
  }

  /// Get badge counter (on iOS the amount is global)
  Future<int> getGlobalBadgeCounter() async {
    final int badgeCount =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_BADGE_COUNT);
    return badgeCount;
  }

  /// Resets the badge counter
  Future<void> resetGlobalBadge() async {
    await _channel.invokeListMethod(CHANNEL_METHOD_RESET_BADGE);
  }

  /// Get the next valid date for a notification schedule
  Future<DateTime?> getNextDate(
    /// A valid Notification schedule model
    NotificationSchedule schedule, {

    /// reference date to simulate a schedule in different time. If null, the reference date will be now
    DateTime? fixedDate,
  }) async {
    fixedDate ??= DateTime.now().toUtc();
    Map parameters = {
      NOTIFICATION_INITIAL_FIXED_DATE: DateUtils.parseDateToString(fixedDate),
      NOTIFICATION_SCHEDULE: schedule.toMap()
    };

    final String? nextDate =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_NEXT_DATE, parameters);

    if (nextDate == null) return null;

    return DateUtils.parseStringToDate(nextDate)!;
  }

  /// Get the current UTC time zone identifier
  Future<String> getUtcTimeZoneIdentifier() async {
    final String utcIdentifier =
        await _channel.invokeMethod(CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER);
    return utcIdentifier;
  }

  /// Get the current Local time zone identifier
  Future<String> getLocalTimeZoneIdentifier() async {
    final String localIdentifier = await _channel
        .invokeMethod(CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER);
    return localIdentifier;
  }

  /// Cancel a single notification and its respective schedule
  Future<void> cancel(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_NOTIFICATION, id);
  }

  /// Dismiss a single notification, without cancel its schedule
  Future<void> dismiss(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_DISMISS_NOTIFICATION, id);
  }

  /// Cancel a single scheduled notification, without dismiss the active notification
  Future<void> cancelSchedule(int id) async {
    _validateId(id);
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_SCHEDULE, id);
  }

  /// Dismiss all active notifications, without cancel the active respective schedules
  Future<void> dismissAllNotifications() async {
    await _channel.invokeMethod(CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS);
  }

  /// Cancel all active notification schedules without dismiss the respective notifications
  Future<void> cancelAllSchedules() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_SCHEDULES);
  }

  /// Cancel and dismiss all notifications and the active schedules
  Future<void> cancelAll() async {
    await _channel.invokeMethod(CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS);
  }

  /// Defines the global or static methods that gonna receive the notification
  /// events. OBS: Only after set at least one method, the notification's events are delivered.
  ///
  /// [onCreatedNotificationMethod] method that gets called when a new notification or schedule is created
  /// [onDisplayedNotificationMethod] method that gets called when a new notification is displayed
  /// [onActionNotificationMethod] method that receives the notifications action
  /// [onDismissedNotificationMethod] method that receives the dismissed notifications
  Future<bool> setListeners({
    required ActionHandler onActionNotificationMethod,
    NotificationHandler? onCreatedNotificationMethod,
    NotificationHandler? onDisplayedNotificationMethod,
    ActionHandler? onDismissedNotificationMethod
  }) async {

    if(_actionHandler != null){
      print('static methods was already setted.');
      return false;
    }

    final CallbackHandle? actionCallbackReference =
      PluginUtilities.getCallbackHandle(onActionNotificationMethod);

    bool result = await _channel.invokeMethod(CHANNEL_METHOD_SET_ACTION_HANDLE, {
      ACTION_HANDLE: actionCallbackReference?.toRawHandle()
    });

    if(!result){
      print('onActionNotificationMethod is not a valid global or static method.');
      return false;
    }

    _actionHandler = onActionNotificationMethod;
    _dismissedHandler = onDismissedNotificationMethod;
    _createdHandler = onCreatedNotificationMethod;
    _displayedHandler = onDisplayedNotificationMethod;

    _startEventListeners();

    return result;
  }
}
