//
//  DartBackgroundService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 04/06/21.
//

import Foundation

public class DartBackgroundExecutor {
    private static let TAG:String = "DartBackgroundExecutor"
    
    public let silentDataQueue:SynchronizedArray = SynchronizedArray<SilentDataRequest>()
        
    private var backgroundEngine:FlutterEngine?
    private var backgroundChannel:FlutterMethodChannel?
    private var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    static var registrar:FlutterPluginRegistrar?
    
    private var _isRunning = false
    public var isRunning:Bool {
        get { return _isRunning }
    }
    
    private var actionReceived:ActionReceived?
    
    private static var instance:DartBackgroundExecutor?
    public static var shared: DartBackgroundExecutor = {
        instance = instance ?? DartBackgroundExecutor()
        return instance!
    }()
    
    var dartCallbackHandle:Int64 = 0
    var silentCallbackHandle:Int64 = 0
        
    func run() {
        _isRunning = true
        
        dartCallbackHandle = DefaultManager.getDartBgCallback()
        silentCallbackHandle = DefaultManager.getActionCallback()
        
        if dartCallbackHandle == 0 {
            Log.d(DartBackgroundExecutor.TAG, "There is no valid callback to handle dart channels.")
            self.closeBackgroundIsolate()
            return
        }
        
        if silentCallbackHandle == 0 {
            Log.d(DartBackgroundExecutor.TAG, "There is no valid callback to handle silent data.")
            self.closeBackgroundIsolate()
            return
        }
        
        guard let dartCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(self.dartCallbackHandle) else {
            Log.d(DartBackgroundExecutor.TAG, "There is no valid callback info to handle dart channels.")
            self.closeBackgroundIsolate()
            return
        }
        
        guard let silentCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(self.silentCallbackHandle) else {
            Log.d(DartBackgroundExecutor.TAG, "There is no valid callback info to handle silent data.")
            self.closeBackgroundIsolate()
            return
        }
        
        runBackgroundThread(dartCallbackInfo: dartCallbackInfo, silentCallbackInfo: silentCallbackInfo)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        
        if(call.method == Definitions.CHANNEL_METHOD_INITIALIZE){
            
            dischargeNextSilentExecution()
            result(true)
            
        } else {
            
            result(
                FlutterError.init(
                    code: SwiftAwesomeNotificationsPlugin.TAG,
                    message: "\(call.method) not implemented",
                    details: call.method
                )
            )

            result(false)
        }
    }
    
    func initializeReverseMethodChannel(backgroundEngine: FlutterEngine){
        
        self.backgroundChannel = FlutterMethodChannel(
            name: Definitions.CHANNEL_METHOD_DART_CALLBACK,
            binaryMessenger: backgroundEngine.binaryMessenger
        )
        
        self.backgroundChannel!.setMethodCallHandler(handle)
    }
    
    func runBackgroundThread(
       dartCallbackInfo:FlutterCallbackInformation,
       silentCallbackInfo:FlutterCallbackInformation
    ) {
        if(self.backgroundEngine != nil){
            Log.d(DartBackgroundExecutor.TAG, "Background isolate already started.")
            self.closeBackgroundIsolate()
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            
            self.backgroundEngine = FlutterEngine(
                name: "AwesomeNotificationsBgEngine",
                project: nil,
                allowHeadlessExecution: true
            )
            
            if self.backgroundEngine == nil {
                Log.d(DartBackgroundExecutor.TAG, "Flutter background engine is not available.")
                self.closeBackgroundIsolate()
                return
            }
            
            self.flutterPluginRegistrantCallback?(self.backgroundEngine!)
            self.initializeReverseMethodChannel(backgroundEngine: self.backgroundEngine!)
            
            self.backgroundEngine!.run(
                withEntrypoint: dartCallbackInfo.callbackName,
                libraryURI: dartCallbackInfo.callbackLibraryPath)
            
            self.backgroundEngine!.viewController = nil
        }
    }
    
    func dischargeNextSilentExecution(){
        if (silentDataQueue.count > 0){
            let silentDataRequest:SilentDataRequest = silentDataQueue.first()!
            self.executeDartCallbackInBackgroundIsolate(silentDataRequest)
        }
        else {
            closeBackgroundIsolate()
        }
    }
    
    func executeDartCallbackInBackgroundIsolate(_ silentDataRequest:SilentDataRequest){
        
        if self.backgroundEngine == nil {
            Log.i(DartBackgroundExecutor.TAG, "A background message could not be handle since" +
                    "dart callback handler has not been registered")
        }
        
        let silentData = silentDataRequest.actionReceived.toMap()
        
        backgroundChannel?.invokeMethod(
            Definitions.CHANNEL_METHOD_SILENCED_CALLBACK,
            arguments: [
                Definitions.ACTION_HANDLE: silentCallbackHandle,
                Definitions.CHANNEL_METHOD_RECEIVED_ACTION: silentData
            ],
            result: { flutterResult in
                silentDataRequest.handler()
                self.finishDartBackgroundExecution()
            }
        )
    }
    
    func finishDartBackgroundExecution(){
        if (silentDataQueue.count == 0) {
            Log.i(DartBackgroundExecutor.TAG, "All silent data fetched.")
            self.closeBackgroundIsolate()
        }
        else {
            Log.i(DartBackgroundExecutor.TAG, "Remaining " + String(silentDataQueue.count) + " silents to finish")
            self.dischargeNextSilentExecution()
        }
    }
    
    func closeBackgroundIsolate() {
        _isRunning = false
        
        self.backgroundEngine?.destroyContext()
        self.backgroundEngine = nil
        
        self.backgroundChannel = nil
    }
}
