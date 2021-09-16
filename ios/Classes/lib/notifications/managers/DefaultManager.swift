//
//  DefaultsManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/21.
//

import Foundation

public class DefaultManager {
    
    static let _sharedInstance = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
    static let _shared:SharedManager = SharedManager(tag: Definitions.SHARED_DEFAULTS)
    
    public static func setActionCallback(_ actionHandle:Int64){
        _sharedInstance!.setValue(actionHandle, forKey: Definitions.ACTION_HANDLE)
    }
    
    public static func setDartBgCallback(_ dartBgHandle:Int64){
        _sharedInstance!.setValue(dartBgHandle, forKey: Definitions.DART_BG_HANDLE)
    }
    
    public static func getActionCallback() -> Int64 {
        return Int64(_sharedInstance!.object(forKey: Definitions.ACTION_HANDLE) as? Int64 ?? 0)
    }
    
    public static func getDartBgCallback() -> Int64 {
        return Int64(_sharedInstance!.object(forKey: Definitions.DART_BG_HANDLE) as? Int64 ?? 0)
    }
    
}
