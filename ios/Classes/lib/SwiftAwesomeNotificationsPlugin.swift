
import UIKit
import Flutter
//import BackgroundTasks
import UserNotifications
    
public class SwiftAwesomeNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    
    private static var _instance:SwiftAwesomeNotificationsPlugin?
    
	static var debug = false
    static let TAG = "AwesomeNotificationsPlugin"
    
    static var firebaseEnabled:Bool = false
    static var firebaseDeviceToken:String?
    
    private var originalUserCenter:UNUserNotificationCenter?
    private var originalUserCenterDelegate:UNUserNotificationCenterDelegate?
    private var originalDelegateHasDidReceive = false
    private var originalDelegateHasWillPresent = false
    
    public static var appLifeCycle:NotificationLifeCycle {
        get { return LifeCycleManager.getLifeCycle(referenceKey: "currentlifeCycle") }
        set (newValue) { LifeCycleManager.setLifeCycle(referenceKey: "currentlifeCycle", lifeCycle: newValue) }
    }
    
#if !ACTION_EXTENSION
    static var registrar:FlutterPluginRegistrar?
    var flutterChannel:FlutterMethodChannel?
#endif

    public static var instance:SwiftAwesomeNotificationsPlugin? {
        get { return _instance }
    }
    
    private static func checkGooglePlayServices() -> Bool {
        return true
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard let jsonData:String = response.notification.request.content.userInfo[Definitions.NOTIFICATION_JSON] as? String else {
                
            if(SwiftAwesomeNotificationsPlugin.debug){
                debugPrint("Received an invalid awesome notification action content. Notification action ignored.")
            }
            
            if(originalUserCenterDelegate != nil && originalDelegateHasDidReceive){
                originalUserCenterDelegate!.userNotificationCenter!(center, didReceive: response, withCompletionHandler: completionHandler)
            }
            else {
                completionHandler()
            }
            return;
        }
        
        var userText:String?
        if let textResponse =  response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }
        
        receiveAction(
            jsonData: jsonData,
            actionKey: response.actionIdentifier,
            userText: userText,
            withCompletionHandler: completionHandler
        )
    }
    
    public func attachNotificationCenterDelegate(){
        
        originalUserCenter = UNUserNotificationCenter.current()
        originalUserCenterDelegate = originalUserCenter!.delegate
        
        originalDelegateHasDidReceive = originalUserCenterDelegate?.responds(
                to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        ) ?? false
        originalDelegateHasWillPresent = originalUserCenterDelegate?.responds(
            to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        ) ?? false
        
        UNUserNotificationCenter.current().delegate = self
        
        //enableFirebase(application)
        //enableScheduler(application)
        rescheduleLostNotifications()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notifications attached to iOS")
        }
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        displayNotification(center, willPresent: notification, withCompletionHandler: completionHandler)
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        attachNotificationCenterDelegate()
        return true
    }
    
    @available(iOS 10.0, *)
    private func displayNotification(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let content:UNNotificationContent = notification.request.content
        
        var arguments:[String : Any?]
        if(content.userInfo[Definitions.NOTIFICATION_JSON] != nil){
            let jsonData:String = content.userInfo[Definitions.NOTIFICATION_JSON] as! String
            arguments = JsonUtils.fromJson(jsonData) ?? [:]
        }
        else {
            arguments = content.userInfo as! [String : Any?]
            
            if(arguments[Definitions.PUSH_NOTIFICATION_CONTENT] is String){
                arguments[Definitions.PUSH_NOTIFICATION_CONTENT] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_CONTENT] as? String)
            }
            
            if(arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] is String){
                arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String)
            }
            
            if(arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] is String){
                arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(arguments[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String)
            }
        }
        
        guard let notificationModel:NotificationModel = NotificationBuilder.jsonDataToNotificationModel(jsonData: arguments)
        else {
            if(SwiftAwesomeNotificationsPlugin.debug){
                Log.d("receiveNotification","Awesome notification data is invalid. Display threatment ignored.")
            }
            
            if(originalUserCenterDelegate != nil && originalDelegateHasWillPresent){
                originalUserCenterDelegate!.userNotificationCenter!(center, willPresent: notification, withCompletionHandler: completionHandler)
            }
            else {
                completionHandler([.alert, .badge, .sound])
            }
            return
        }
        
        /*
        if(content.userInfo["updated"] == nil){
            
            let pushData = notificationModel.toMap()
            let updatedJsonData = JsonUtils.toJson(pushData)
            
            let content:UNMutableNotificationContent =
                UNMutableNotificationContent().copyContent(from: content)
            
            content.userInfo[Definitions.NOTIFICATION_JSON] = updatedJsonData
            content.userInfo["updated"] = true
            
            let request = UNNotificationRequest(identifier: notificationModel!.content!.id!.description, content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
            }
            
            completionHandler([])
            return
        }
        */
    
        let notificationReceived:NotificationReceived? = NotificationReceived(notificationModel.content)
        if(notificationReceived != nil){
            
            notificationModel.content!.displayedLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                        
            let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: notificationModel.content!.channelKey!)
            
            alertOnlyOnceNotification(
                channel?.onlyAlertOnce,
                notificationReceived: notificationReceived!,
                completionHandler: completionHandler
            )
            
            if CreatedManager.getCreatedByKey(id: notificationReceived!.id!) != nil {
                SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: notificationReceived!)
            }
            
            DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
            
            SwiftAwesomeNotificationsPlugin.displayEvent(notificationReceived: notificationReceived!)
            
            /*
            if(notificationModel.schedule != nil){
                                
                do {
                    try NotificationSenderAndScheduler().send(
                        createdSource: notificationModel.content!.createdSource!,
                        notificationModel: notificationModel,
                        completion: { sent, content, error in
                        
                        }
                    )
                } catch {
                    // Fallback on earlier versions
                }
            }
            */
        }
    }
    
    @available(iOS 10.0, *)
    private func alertOnlyOnceNotification(_ alertOnce:Bool?, notificationReceived:NotificationReceived, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        if(alertOnce ?? false){
            
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                
                for notification in notifications {
                    if notification.request.identifier == String(notificationReceived.id!) {
                        
                        self.shouldDisplay(
                            notificationReceived: notificationReceived,
                            options: [.alert, .badge],
                            completionHandler: completionHandler
                        )
                        
                        return
                    }
                }
            }
            
        }
            
        self.shouldDisplay(
            notificationReceived: notificationReceived,
            options: [.alert, .badge, .sound],
            completionHandler: completionHandler
        )
    }
    
    @available(iOS 10.0, *)
    private func shouldDisplay(notificationReceived:NotificationReceived, options:UNNotificationPresentationOptions, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        let currentLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        if(
            (notificationReceived.displayOnForeground! && currentLifeCycle == .Foreground)
                ||
            (notificationReceived.displayOnBackground! && currentLifeCycle == .Background)
        ){
            completionHandler(options)
        }
        completionHandler([])
    }
    
#if !ACTION_EXTENSION
    private func receiveAction(jsonData: String?, actionKey:String?, userText:String?, withCompletionHandler completionHandler: @escaping () -> Void){
		
        if(SwiftAwesomeNotificationsPlugin.appLifeCycle == .AppKilled){
            fireBackgroundLostEvents()
        }
        
        if #available(iOS 10.0, *) {
            let actionReceived:ActionReceived? = NotificationBuilder.buildNotificationActionFromJson(jsonData: jsonData, actionKey: actionKey, userText: userText)
            
            if(SwiftAwesomeNotificationsPlugin.appLifeCycle == .AppKilled && actionReceived != nil &&
                (
                    actionReceived!.notificationActionType == .SilentAction ||
                    actionReceived!.notificationActionType == .SilentBackgroundAction
                )
            ){
                DartBackgroundService.enqueueSilentDataProcessing(actionReceived: actionReceived!, handler: completionHandler)
                return
            }
            
            if actionReceived?.dismissedDate == nil {

                if(SwiftAwesomeNotificationsPlugin.debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification action received");
				}
                flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, arguments: actionReceived?.toMap())
            }
            else {

                if(SwiftAwesomeNotificationsPlugin.debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification dismissed");
				}
                flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, arguments: actionReceived?.toMap())
            }
            
        }        
        completionHandler()
    }
#endif
    
    @available(iOS 10.0, *)
    public static func processNotificationContent(_ notification: UNNotification) -> UNNotification{
        Log.d(SwiftAwesomeNotificationsPlugin.TAG, "processNotificationContent SwiftAwesomeNotificationsPlugin")
        return notification
    }
    
    public static func createEvent(notificationReceived:NotificationReceived){
		if(debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification created")
		}
        
        let lifecycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        
        if(SwiftUtils.isRunningOnExtension() || lifecycle == .AppKilled){
            CreatedManager.saveCreated(received: notificationReceived)
        } else {
            _ = CreatedManager.removeCreated(id: notificationReceived.id!)
            
            SwiftAwesomeNotificationsPlugin.instance?.flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, arguments: notificationReceived.toMap())
        }
    }
    
    public static func displayEvent(notificationReceived:NotificationReceived){
		if(debug){
			Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Notification displayed")
		}

        let lifecycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        
        if(SwiftUtils.isRunningOnExtension() || lifecycle == .AppKilled){
            DisplayedManager.saveDisplayed(received: notificationReceived)
        } else {
            _ = DisplayedManager.removeDisplayed(id: notificationReceived.id!)
            
            SwiftAwesomeNotificationsPlugin.instance?.flutterChannel?.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, arguments: notificationReceived.toMap())
        }
    }
    
    private static var didIRealyGoneBackground:Bool = true
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
	
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        
        if(SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground){
            fireBackgroundLostEvents()
        }
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
        
        /*if(SwiftAwesomeNotificationsPlugin.hasGoneToAuthorizationPage){
            SwiftAwesomeNotificationsPlugin.hasGoneToAuthorizationPage = false
            
            SwiftAwesomeNotificationsPlugin.pendingAuthorizationReturn() = result
            SwiftAwesomeNotificationsPlugin.lastChannelKeyRequested = channelKey
        }*/
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (DidBecomeActive) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        
        // applicationWillTerminate is not always get called, so the Background state is not correct defined in this cases
        //SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Foreground
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = false
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillResignActive) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        
        // applicationWillTerminate is not always get called, so the AppKilled state is not correct defined in this cases
        //SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        SwiftAwesomeNotificationsPlugin.didIRealyGoneBackground = true
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (DidEnterBackground) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
        
        //startBackgroundScheduler()
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
	
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.Background
        
        //stopBackgroundScheduler()
        rescheduleLostNotifications()
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillEnterForeground) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled
        
        //SwiftAwesomeNotificationsPlugin.rescheduleBackgroundTask()
		
        if(SwiftAwesomeNotificationsPlugin.debug){
			Log.d(
				SwiftAwesomeNotificationsPlugin.TAG,
				"Notification lifeCycle: (WillTerminate) " 
					+ SwiftAwesomeNotificationsPlugin.appLifeCycle.rawValue
			)
		}
    }

    private static func requestPermissions() -> Bool {
        if #available(iOS 10.0, *) {
            NotificationBuilder.requestPermissions(completion: { authorized in
				if(debug){
					Log.d(SwiftAwesomeNotificationsPlugin.TAG, 
					authorized ? "Notifications authorized" : "Notifications not authorized")
				}
            })
        }
        return true
    }
    
    public func clearDeactivatedSchedules(){
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isEmptyLists(schedules)){
                    for notificationModel in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier != String(notificationModel.content!.id!) {
                                founded = true
                                break;
                            }
                        }
                        if(!founded){
                            ScheduleManager.cancelScheduled(id: notificationModel.content!.id!)
                        }
                    }
                }
            } else {
                ScheduleManager.cancelAllSchedules();
            }
        })
    }
    
    public func rescheduleLostNotifications(){
        let referenceDate = Date()
        
        let lostSchedules = ScheduleManager.listPendingSchedules(referenceDate: referenceDate)
        for notificationModel in lostSchedules {
            
            do {
                let hasNextValidDate:Bool = (notificationModel.schedule?.hasNextValidDate() ?? false)
                if  notificationModel.schedule?.createdDate == nil || !hasNextValidDate {
                    throw AwesomeNotificationsException.notificationExpired
                }
                
                if #available(iOS 10.0, *) {
                    try NotificationSenderAndScheduler().send(
                        createdSource: notificationModel.content!.createdSource!,
                        notificationModel: notificationModel,
                        completion: { sent, content, error in
                        }
                    )
                }
            } catch {
                let _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
            }
        }
        
        clearDeactivatedSchedules();
    }

    public func fireBackgroundLostEvents(){
        
        let lostCreated = CreatedManager.listCreated()
        for createdNotification in lostCreated {
            SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: createdNotification)
        }
        
        DisplayedManager.reloadLostSchedulesDisplayed(referenceDate: Date())
        
        let lostDisplayed = DisplayedManager.listDisplayed()
        for displayedNotification in lostDisplayed {
            SwiftAwesomeNotificationsPlugin.displayEvent(notificationReceived: displayedNotification)
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Definitions.CHANNEL_FLUTTER_PLUGIN, binaryMessenger: registrar.messenger())
        let instance = SwiftAwesomeNotificationsPlugin()

        instance.initializeFlutterPlugin(registrar: registrar, channel: channel)
        SwiftAwesomeNotificationsPlugin._instance = instance
    }

    private func initializeFlutterPlugin(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.flutterChannel = channel
        
        registrar.addMethodCallDelegate(self, channel: self.flutterChannel!)
        registrar.addApplicationDelegate(self)
                
        SwiftAwesomeNotificationsPlugin.registrar = registrar        
        SwiftAwesomeNotificationsPlugin.appLifeCycle = NotificationLifeCycle.AppKilled        
    }
    
#if !ACTION_EXTENSION
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		
		do {
		
			switch call.method {
				
				case Definitions.CHANNEL_METHOD_INITIALIZE:
                    try channelMethodInitialize(call: call, result: result)
					return
				
                case Definitions.CHANNEL_METHOD_SET_ACTION_HANDLE:
                    try channelMethodSetActionHandle(call: call, result: result)
                    return
                    
				case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                    try channelMethodGetDrawableData(call: call, result: result)
					return;
				/*
				case Definitions.CHANNEL_METHOD_IS_FCM_AVAILABLE:
                    try channelMethodIsFcmAvailable(call: call, result: result)
					return
			  
				case Definitions.CHANNEL_METHOD_GET_FCM_TOKEN:
                    try channelMethodGetFcmToken(call: call, result: result)
					return
				*/
				case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                    try channelMethodIsNotificationAllowed(call: call, result: result)
					return
                    
                case Definitions.CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE:
                    try channelMethodShowNotificationConfigPage(call: call, result: result)
                    return

				case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                    try channelMethodRequestNotification(call: call, result: result)
					return
						
				case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                    try channelMethodCreateNotification(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                    try channelMethodSetChannel(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
                    try channelMethodRemoveChannel(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                    try channelMethodGetBadgeCounter(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                    try channelMethodSetBadgeCounter(call: call, result: result)
					return
					
				case Definitions.CHANNEL_METHOD_RESET_BADGE:
                    try channelMethodResetBadge(call: call, result: result)
					return
                    
                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATION:
                    try channelMethodDismissNotification(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                    try channelMethodCancelSchedule(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                    try channelMethodCancelNotification(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS:
                    try channelMethodDismissAllNotifications(call: call, result: result)
                    return
					
				case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                    try channelMethodCancelAllSchedules(call: call, result: result)
					return
                    
                case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                    try channelMethodCancelAllNotifications(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_NEXT_DATE:
                    try channelMethodGetNextDate(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER:
                    try channelMethodGetUTCTimeZoneIdentifier(call: call, result: result)
                    return
                    
                case Definitions.CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER:
                    try channelMethodGetLocalTimeZoneIdentifier(call: call, result: result)
                    return
					
				case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
					try channelMethodListAllSchedules(call: call, result: result)
					return

				default:
					result(FlutterError.init(code: "methodNotFound", message: "method not found", details: call.method));
					return
			}

        } catch {

            result(
                FlutterError.init(
                    code: SwiftAwesomeNotificationsPlugin.TAG,
                    message: "\(error)",
                    details: error.localizedDescription
                )
            )

            result(false)
        }
    }
    
    private func channelMethodGetNextDate(call: FlutterMethodCall, result: @escaping FlutterResult) throws {

		let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let fixedDate:String? = platformParameters[Definitions.NOTIFICATION_INITIAL_FIXED_DATE] as? String
        
        let timezone:String =
            (platformParameters[Definitions.NOTIFICATION_SCHEDULE_TIMEZONE] as? String) ?? DateUtils.utcTimeZone.identifier
        
		guard let scheduleData:[String : Any?] = platformParameters[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? [String : Any?]
		else { result(nil); return }
        
        var scheduleModel:NotificationScheduleModel?
        if(scheduleData[Definitions.NOTIFICATION_SCHEDULE_INTERVAL] != nil){
            scheduleModel = NotificationIntervalModel().fromMap(arguments: scheduleData) as? NotificationScheduleModel
        } else {
            scheduleModel = NotificationCalendarModel().fromMap(arguments: scheduleData) as? NotificationScheduleModel
        }
        if(scheduleModel == nil){ result(nil); return }
        
        let nextValidDate:Date? = DateUtils.getNextValidDate(scheduleModel: scheduleModel!, fixedDate: fixedDate, timeZone: timezone)

		if(nextValidDate == nil){ result(nil); return }
        let convertedDate:String? = DateUtils.dateToString(nextValidDate, timeZone: timezone)

		result(convertedDate)
    }
    
    private func channelMethodGetUTCTimeZoneIdentifier(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(DateUtils.utcTimeZone.identifier)
    }
    
    private func channelMethodGetLocalTimeZoneIdentifier(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(DateUtils.localTimeZone.identifier)
    }
    
    private func channelMethodListAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            var serializeds:[[String:Any?]]  = []
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isEmptyLists(schedules)){
                    for notificationModel in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier == String(notificationModel.content!.id!) {
                                founded = true
                                let serialized:[String:Any?] = notificationModel.toMap()
                                serializeds.append(serialized)
                                break;
                            }
                        }
                        if(!founded){
                            ScheduleManager.cancelScheduled(id: notificationModel.content!.id!)
                        }
                    }
                }
            } else {
                ScheduleManager.cancelAllSchedules();
            }

            result(serializeds)
        })
    }
    
    private func channelMethodSetChannel(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let channelData:[String:Any?] = call.arguments as! [String:Any?]
		let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: channelData) as! NotificationChannelModel
		
		ChannelManager.saveChannel(channel: channel)
		
		Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel updated")
		result(true)
    }
    
    private func channelMethodRemoveChannel(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let channelKey:String? = call.arguments as? String
				
		if (channelKey == nil){
			
			result(
				FlutterError.init(
					code: "Empty channel key",
					message: "Empty channel key",
					details: channelKey
				)
			)
		}
		else {
			
			let removed:Bool = ChannelManager.removeChannel(channelKey: channelKey!)
		 
			if removed {
				
				Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel removed")
				result(removed)
			}
			else {
				
				Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Channel '\(channelKey!)' not found")
				result(removed)
			}
		}
    }
    
    private func channelMethodInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
	
		let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        let dartBgHandle:Int64 = platformParameters[Definitions.DART_BG_HANDLE] as? Int64 ?? 0
		let defaultIconPath:String? = platformParameters[Definitions.DEFAULT_ICON] as? String
		let channelsData:[Any] = platformParameters[Definitions.INITIALIZE_CHANNELS] as? [Any] ?? []

		try setDefaultConfigurations(
			defaultIconPath,
            dartBgHandle,
			channelsData
		)
        
		Log.d(SwiftAwesomeNotificationsPlugin.TAG, "Awesome Notifications service initialized")
					
		fireBackgroundLostEvents()
		
		result(true)
    }

    private func channelMethodSetActionHandle(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        let actionHandle:Int64 = platformParameters[Definitions.ACTION_HANDLE] as? Int64 ?? 0
        
        DefaultManager.setActionCallback(actionHandle)
            
        result(true)
    }

    private func channelMethodGetDrawableData(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
		let bitmapReference:String = call.arguments as! String
			
		let image:UIImage = BitmapUtils.getBitmapFromSource(bitmapPath: bitmapReference)!
		let data:Data? = UIImage.pngData(image)()

		if(data == nil){
			result(nil)
		}
		else {
			let uInt8ListBytes:FlutterStandardTypedData = FlutterStandardTypedData.init(bytes: data!)
			result(uInt8ListBytes)
		}
    }
    
    /*private func channelMethodGetFcmToken(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        result(FlutterError.init(
            code: "Method deprecated",
            message: "Method deprecated",
            details: "channelMethodGetFcmToken"
        ))
         
        let token = requestFirebaseToken()
        result(token)
        
        result(nil)
    }
		
    private func channelMethodIsFcmAvailable(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        result(FlutterError.init(
            code: "Method deprecated",
            message: "Method deprecated",
            details: "channelMethodGetFcmToken"
        ))
        
        let token = requestFirebaseToken()
        result(!StringUtils.isNullOrEmpty(token))
         
    }*/
    
    private func isChannelEnabled(channelKey:String) -> Bool {
        let channel:NotificationChannelModel? = ChannelManager.getChannelByKey(channelKey: channelKey)
        return
            channel?.importance == nil ?
                false :
                channel?.importance != NotificationImportance.None
    }
    
    private func channelMethodIsNotificationAllowed(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let platformParameters:[String:Any?]? = call.arguments as? [String:Any?] ?? [:]
        let channelKey:String? = platformParameters?[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        if #available(iOS 10.0, *) {
            NotificationBuilder.isNotificationAllowed(completion: { [self] (allowed) in
                if(allowed && channelKey != nil){
                    result(isChannelEnabled(channelKey: channelKey!))
                    return
                }
                result(allowed)
            })
        }
        else {
            result(nil)
        }
    }
    
    private func channelMethodShowNotificationConfigPage(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    result(nil)// Prints true
                })
            }
        }
        else {
            result(nil)
        }
    }

    private func channelMethodRequestNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        let platformParameters:[String:Any?]? = call.arguments as? [String:Any?] ?? [:]
        let channelKey:String? = platformParameters?[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        if #available(iOS 10.0, *) {
            NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
                if(!allowed){
                    NotificationBuilder.requestPermissions { [self] (allowed) in
                        if(allowed && channelKey != nil){
                            result(isChannelEnabled(channelKey: channelKey!))
                            return
                        }
                        result(allowed)
                    }
                }
                else {
                    result(true)
                }
            })
        }
        else {
            result(nil)
        }
    }
    
    private func channelMethodGetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            result(NotificationBuilder.getBadge().intValue)
        }
        else {
            result(0)
        }
    }
    
    private func channelMethodSetBadgeCounter(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        let platformParameters:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
        let value:Int? = platformParameters[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE] as? Int
        //let channelKey:String? = platformParameters[Definitions.NOTIFICATION_CHANNEL_KEY] as? String
        
        if #available(iOS 10.0, *), value != nil {
            NotificationBuilder.setBadge(value!)
        }
        result(nil)
    }
    
    private func channelMethodResetBadge(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        if #available(iOS 10.0, *) {
            NotificationBuilder.resetBadge()
        }
        result(nil)
    }
    
    private func channelMethodDismissNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.dismissNotification(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelSchedule(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelSchedule(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        guard let notificationId:Int = call.arguments as? Int else {
            result(false); return
        }
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelNotification(id: notificationId))
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodDismissAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.dismissAllNotifications())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }
    
    private func channelMethodCancelAllSchedules(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllSchedules())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }

    private func channelMethodCancelAllNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
        if #available(iOS 10.0, *) {
            result(NotificationSenderAndScheduler.cancelAllNotifications())
            return
        } else {
            // Fallback on earlier versions
        }
        
        result(false)
    }

    private func channelMethodCreateNotification(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
        
		let pushData:[String:Any?] = call.arguments as? [String:Any?] ?? [:]
		let notificationModel:NotificationModel? = NotificationModel().fromMap(arguments: pushData) as? NotificationModel
		
		if(notificationModel != nil){
				
			if #available(iOS 10.0, *) {
				try NotificationSenderAndScheduler().send(
					createdSource: NotificationSource.Local,
					notificationModel: notificationModel,
					completion: { sent, content, error in
					
						if error != nil {
							let flutterError:FlutterError?
							if let notificationError = error as? AwesomeNotificationsException {
								switch notificationError {
									case AwesomeNotificationsException.notificationNotAuthorized:
										flutterError = FlutterError.init(
											code: "notificationNotAuthorized",
											message: "Notifications are disabled",
											details: nil
										)
									case AwesomeNotificationsException.cronException:
										flutterError = FlutterError.init(
											code: "cronException",
											message: notificationError.localizedDescription,
											details: nil
										)
									default:
										flutterError = FlutterError.init(
											code: "exception",
											message: "Unknow error",
											details: notificationError.localizedDescription
										)
								}
							}
							else {
								flutterError = FlutterError.init(
									code: error.debugDescription,
									message: error?.localizedDescription,
									details: nil
								)
							}
							result(flutterError)
							return
						}
						else {
							result(sent)
							return
						}
						
					}
				)
			} else {
				// Fallback on earlier versions
				
				result(true)
				return
			}
		}
		else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Notification content is invalid")
		}
        
        result(false)
    }
#endif
    
    private func setDefaultConfigurations(_ defaultIconPath:String?,_ dartBgHandle:Int64,_ channelsData:[Any]) throws {
        
        DefaultManager.setDartBgCallback(dartBgHandle)
        
        for anyData in channelsData {
            if let channelData = anyData as? [String : Any?] {
                let channel:NotificationChannelModel? = (NotificationChannelModel().fromMap(arguments: channelData) as? NotificationChannelModel)
                
                if(channel != nil){
                    ChannelManager.saveChannel(channel: channel!)
                }
            }
        }
    }
}
