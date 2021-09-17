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
    
    public static func enqueueSilentDataProcessing(
        actionReceived:ActionReceived,
        handler: @escaping () -> ()
    ){
        DartBackgroundExecutor.shared.silentDataQueue.add(SilentDataRequest(
            actionReceived: actionReceived, handler: handler
        ))
        
        if !(DartBackgroundExecutor.shared.isRunning) {
            Log.i(TAG, "Dart background service has started")
            DartBackgroundExecutor.shared.run()
        }
    }
}
