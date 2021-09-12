//
//  DartBackgroundService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 04/06/21.
//

import Foundation

public class DartBackgroundExecutor: FlutterMethodChannel {
    private static let TAG:String = "DartBackgroundExecutor"
    
    public let requestQueue:SynchronizedArray = SynchronizedArray<SilentDataRequest>()
    
    private let application: UIApplication? = nil
    private var identifier = UIBackgroundTaskIdentifier.invalid
    private var backgroundChannel:FlutterMethodChannel?
    
    static var registrar:FlutterPluginRegistrar?
    
    private var dartCallbackInfo:FlutterCallbackInformation?
    private var silentCallbackInfo:FlutterCallbackInformation?
    
    private var _isRunning = false
    public var isRunning:Bool {
        get { return _isRunning }
    }
    
    private var actionReceived:ActionReceived?
    
    static var shared: DartBackgroundExecutor = {
        let instance = DartBackgroundExecutor()
        return instance
    }()

    private init() {}
    
    var dartCallbackHandle:Int64 = 0
    var silentCallbackHandle:Int64 = 0
    
    func initializeFlutterIsolate(){
        FlutterEngine.init(name: TAG)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
                
        backgroundChannel = FlutterMethodChannel(
            name: FcmDefinitions.CHANNEL_METHOD_DART_CALLBACK,
            binaryMessenger: backgroundEngine
        )
        
        registrar.addMethodCallDelegate(self, channel: backgroundChannel)
        self.registrar = registrar
    }
    
    func run() {
        _isRunning = true
        
        dartCallbackHandle = FcmDefaultsManager.getDartBgCallback()
        silentCallbackHandle = FcmDefaultsManager.getSilentCallback()
        
        if dartCallbackHandle == 0 {
            Log.e(DartBackgroundExecutor.TAG, "There is no valid callback to handle dart channels.")
            self.end()
            return
        }
        
        if silentCallbackHandle == 0 {
            Log.e(DartBackgroundExecutor.TAG, "There is no valid callback to handle silent data.")
            self.end()
            return
        }
        
        guard dartCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(self.dartCallbackHandle) else {
            Log.e(DartBackgroundExecutor.TAG, "There is no valid callback info to handle dart channels.")
            self.end()
            return
        }
        
        guard silentCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(self.silentCallbackHandle) else {
            Log.e(DartBackgroundExecutor.TAG, "There is no valid callback info to handle silent data.")
            self.end()
            return
        }
        
        begin()
        //handler(backgroundTask)
    }
    
    func begin() {
        DispatchQueue.global(qos: .background).async {
            
            let backgroundEngine = FlutterEngine(
                name: "backgroundEngine",
                project: nil,
                allowHeadlessExecution: true
            )
            
            backgroundEngine.run(
                withEntrypoint: dartCallbackInfo?.callbackName,
                libraryURI: dartCallbackInfo?.callbackLibraryPath)
            
            backgroundEngine.viewController = nil
            
            backgroundChannel = FlutterMethodChannel(
                name: FcmDefinitions.CHANNEL_METHOD_DART_CALLBACK,
                binaryMessenger: backgroundEngine
            )
            
            repeat {
                
            }
            while request.count > 0
            
            self.end()
        }
    }
    
    func end() {
        _isRunning = false
    }
}
