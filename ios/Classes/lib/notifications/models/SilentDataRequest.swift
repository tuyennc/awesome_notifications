//
//  SilentDataRequest.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 12/09/21.
//

import Foundation

public class SilentDataRequest {
    public let actionReceived: ActionReceived
    public let handler: () -> ()
    
    init(actionReceived:ActionReceived, handler: @escaping () -> ()){
        self.actionReceived = actionReceived
        self.handler = handler
    }
}
