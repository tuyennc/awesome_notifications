//
//  ActionReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class ActionReceived : NotificationReceived {
    
    var actionKey: String?
    var actionInput: String?

    var actionLifeCycle: NotificationLifeCycle?
    var dismissedLifeCycle: NotificationLifeCycle?
    var actionDate: String?
    var dismissedDate: String?
    
    override init(_ contentModel:NotificationContentModel?){
        super.init(contentModel)
        
        if(contentModel == nil){ return }
    }
    
    override public func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        _ = super.fromMap(arguments: arguments)
        
        self.actionKey       = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_ACTION_KEY, arguments: arguments)
        self.actionInput     = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_ACTION_INPUT, arguments: arguments)
        
        self.actionDate      = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_ACTION_DATE, arguments: arguments)
        self.dismissedDate   = MapUtils<String>.getValueOrDefault(reference: Definitions.NOTIFICATION_DISMISSED_DATE, arguments: arguments)
        
        self.actionLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_ACTION_LIFECYCLE, arguments: arguments)
        self.dismissedLifeCycle = EnumUtils<NotificationLifeCycle>.getEnumOrDefault(reference: Definitions.NOTIFICATION_DISMISSED_LIFECYCLE, arguments: arguments)
        
        return self
    }
    
    override public func toMap() -> [String : Any?] {
        var dataMap:[String : Any?] = super.toMap()
                
        if(actionKey != nil) {dataMap[Definitions.NOTIFICATION_ACTION_KEY] = self.actionKey}
        if(actionInput != nil) {dataMap[Definitions.NOTIFICATION_ACTION_INPUT] = self.actionInput}
        
        if(actionLifeCycle != nil) {dataMap[Definitions.NOTIFICATION_ACTION_LIFECYCLE] = self.actionLifeCycle?.rawValue}
        if(dismissedLifeCycle != nil) {dataMap[Definitions.NOTIFICATION_DISMISSED_LIFECYCLE] = self.dismissedLifeCycle?.rawValue}
        if(actionDate != nil) {dataMap[Definitions.NOTIFICATION_ACTION_DATE] = self.actionDate}
        if(dismissedDate != nil) {dataMap[Definitions.NOTIFICATION_DISMISSED_DATE] = self.dismissedDate}
        
        return dataMap
    }
    
    override public func validate() throws {
        
    }
    
}
