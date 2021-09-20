//
//  DartBackgroundServices.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 07/06/21.
//

import Foundation

class DartBackgroundService {
    private static let TAG:String = "DartBackgroundService"
    
    private static var instance:DartBackgroundService?
    static var shared: DartBackgroundService = {
        instance = instance ?? DartBackgroundService()
        return instance!
    }()

    private init() {}
    
    public static func executeAction(
        actionReceived:ActionReceived,
        handler: @escaping () -> ()
    ){
        Log.d(TAG, "A new Dart background service has started")
        
        let silentActionRequest:SilentActionRequest = SilentActionRequest(
            actionReceived: actionReceived,
            handler: handler
        )
        
        let dartCallbackHandle: Int64 = DefaultManager.getDartBgCallback()
        let silentCallbackHandle: Int64 = DefaultManager.getActionCallback()
        
        if dartCallbackHandle == 0 {
            Log.d(DartBackgroundService.TAG,
                  "A background message could not be handled in Dart because there is no valid onActionReceivedMethod handler register")
            return
        }
        
        if silentCallbackHandle == 0 {
            Log.d(DartBackgroundService.TAG,
                  "A background message could not be handled in Dart because there is no valid dart background handler register"
            )
            return
        }
        
        DartBackgroundExecutor.shared.runBackgroundExecutor(
            silentActionRequest: silentActionRequest,
            dartCallbackHandle: dartCallbackHandle,
            silentCallbackHandle: silentCallbackHandle
        )
    }
}
