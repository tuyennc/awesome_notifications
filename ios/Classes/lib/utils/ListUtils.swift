//
//  ListUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class ListUtils {

    public static func isEmptyLists(_ list: [AnyObject]?) -> Bool {
        return list?.isEmpty ?? true
    }
}
