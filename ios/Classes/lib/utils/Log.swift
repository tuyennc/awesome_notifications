//
//  Log.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 10/09/20.
//

import Foundation


public class Log {
    
    public static func d(_ tag:String, _ message:String){
        #if DEBUG
            debugPrint(tag+": "+message)
        #endif
    }
    
    public static func i(_ tag:String, _ message:String){
        print(tag+": "+message)
    }
    
}
