#import "AwesomeNotificationsPlugin.h"
#if __has_include(<awesome_notifications/awesome_notifications-Swift.h>)
#import <awesome_notifications/awesome_notifications-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "awesome_notifications-Swift.h"
#endif

@implementation AwesomeNotificationsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // FIXME: temporary disable this plugin in iOS for avoid conflict with flutter_local_notification which work on iOS
  // [SwiftAwesomeNotificationsPlugin registerWithRegistrar:registrar];
}

@end

