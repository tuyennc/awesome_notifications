//
//  DefaultsManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/21.
//

import Foundation

public class DefaultManager {
    
    static let _shared:SharedManager = SharedManager(tag: Definitions.SHARED_DEFAULTS)
    
    public static func setActionCallback(_ actionHandle:Int64){
        _shared.set(String(actionHandle), referenceKey: Definitions.ACTION_HANDLE)
    }
    
    public static func setDartBgCallback(_ dartBgHandle:Int64){
        _shared.set(String(dartBgHandle), referenceKey: Definitions.DART_BG_HANDLE)
    }
    
    public static func getActionCallback() -> Int64 {
        return Int64( _shared.get(referenceKey: Definitions.ACTION_HANDLE) ?? 0 ) ?? 0
    }
    
    public static func getDartBgCallback() -> Int64 {
        return Int64( _shared.get(referenceKey: Definitions.DART_BG_HANDLE) ?? 0 ) ?? 0
    }
    
}
