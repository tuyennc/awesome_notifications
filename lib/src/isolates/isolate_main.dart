import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

void dartIsolateMain() {

  // Initialize state necessary for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  // We establish a new flutter native channel to be able to receive data in
  // inverse direction
  const MethodChannel _channel = MethodChannel(DART_REVERSE_CHANNEL);

  // This is where we handle background silent events
  _channel.setMethodCallHandler((MethodCall call) async {

    switch (call.method) {

      case CHANNEL_METHOD_ISOLATE_CALLBACK:
        await channelMethodIsolateCallbackHandle(call);
        break;

      default:
        throw UnimplementedError("${call.method} has not been implemented");
    }
  });

  // for last, the native channel is initialize to allow to call CHANNEL_METHOD_SILENCED_CALLBACK
  _channel.invokeMethod<void>(CHANNEL_METHOD_INITIALIZE);
}

/// This method handle the silent callback as a flutter plugin
Future<void> channelMethodIsolateCallbackHandle(MethodCall call) async {
  try {
    bool success =
    await receiveSilentAction((call.arguments as Map).cast<String, dynamic>());

    if (!success)
      throw AwesomeNotificationsException('Silent data could not be recovered');

  } catch (e) {
    print(
        "Awesome Notifications FCM: An error occurred in your background messaging handler:");
    print(e);
  }
}

/// Calls the silent data method, if is a valid static one
Future<bool> receiveSilentAction(Map<String, dynamic> arguments) async {

  final CallbackHandle silentCallbackHandle = CallbackHandle.fromRawHandle(arguments[SILENT_HANDLE]);

  // PluginUtilities.getCallbackFromHandle performs a lookup based on the
  // callback handle and returns a tear-off of the original callback.
  final SilentActionHandler? onSilentDataHandle
    = PluginUtilities.getCallbackFromHandle(silentCallbackHandle) as SilentActionHandler?;

  if (onSilentDataHandle == null) {
    throw IsolateCallbackException('could not find silent callback');
  }

  Map<String, dynamic> silentMap = Map<String, dynamic>.from(arguments[NOTIFICATION_SILENT_ACTION]);
  final SilentAction silentAction = SilentAction().fromMap(silentMap);
  await onSilentDataHandle(silentAction);

  return true;
}