//
//  DartBackgroundServices.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 07/06/21.
//

import Foundation

class DartBackgroundService {
    private static let TAG:String = "DartBackgroundService"
    
    private static var dartBackgroundExecutor:DartBackgroundExecutor?
    
    static var shared: DartBackgroundService = {
        let instance = DartBackgroundService()
        return instance
    }()

    private init() {}
    
    public static func enqueueSilentDataProcessing(
        actionReceived:ActionReceived,
        handler: @escaping () -> ()
    ){
        dartBackgroundExecutor?.requestQueue.add(SilentDataRequest(
            actionReceived: actionReceived, handler: handler
        ))
        
        if !(DartBackgroundService.dartBackgroundExecutor?.isRunning ?? true) {
            Log.i(TAG, "Dart background service has started")
            dartBackgroundExecutor?.run()
        }
    }
}
