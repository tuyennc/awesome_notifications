//
//  NotificationService.swift
//  AwesomeServiceExtension
//
//  Created by Rafael Setragni on 16/10/20.
//

@available(iOS 10.0, *)
open class AwesomeServiceExtension: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var content: UNMutableNotificationContent?
    //var fcmService: FCMService?
    var notificationModel: NotificationModel?
    

    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ){
        self.contentHandler = contentHandler
        self.content = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let content = content {
            
            if(!StringUtils.isNullOrEmpty(content.userInfo["gcm.message_id"] as? String)){
                print("FCM received")
                
                let title:String? = content.title
                let body:String?  = content.body
                var image:String?
                
                if let options = content.userInfo["fcm_options"] as? NSDictionary {
                    image = options["image"] as? String
                }
                
                if content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] == nil {
                    
                    notificationModel = NotificationModel()
                    notificationModel!.content = NotificationContentModel()
                    
                    notificationModel!.content!.id = Int.random(in: 1..<2147483647)
                    notificationModel!.content!.channelKey = "basic_channel"
                    notificationModel!.content!.title = title
                    notificationModel!.content!.body = body
                    notificationModel!.content!.playSound = true
                    
                    if !StringUtils.isNullOrEmpty(image) {
                        notificationModel!.content!.notificationLayout = NotificationLayout.BigPicture
                        notificationModel!.content!.bigPicture = image
                    }
                    else {
                        notificationModel!.content!.notificationLayout = NotificationLayout.Default
                    }
                }
                else {
                    
                    var mapData:[String:Any?] = [:]
                    
                    mapData[Definitions.PUSH_NOTIFICATION_CONTENT]  = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_BUTTONS]  = JsonUtils.fromJsonArr(content.userInfo[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String)
                    
                    notificationModel = NotificationModel().fromMap(arguments: mapData) as? NotificationModel
                    
                }
                
                NotificationBuilder.setUserInfoContent(notificationModel: notificationModel!, content: content)
                
                content.title = notificationModel?.content?.title ?? ""
                content.body = notificationModel?.content?.body ?? ""
                
                if let notificationModel = notificationModel {
                    do {
                        try NotificationSenderAndScheduler().send(
                            createdSource: NotificationSource.Firebase,
                            notificationModel: notificationModel,
                            content: content,
                            completion: { sent, newContent ,error  in
                                
                                if sent {
                                    contentHandler(newContent ?? content)
                                    return
                                }
                                else {
                                    contentHandler(UNNotificationContent())
                                    return
                                }
                                
                            }
                        )
                    } catch {
                    }
                }
            }
            contentHandler(content)
        }
    }
    
    public override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let content =  content {
            
            /*if let fcmService = self.fcmService {
                if let content = fcmService.serviceExtensionTimeWillExpire(content) {
                    contentHandler(content)
                }
            }
            else {
                contentHandler(content)
            }*/
            contentHandler(content)
        }
    }

}
