//
//  generalFunctions.swift
//  UOless
//
//  Created by Rob Everhardt on 01/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation
import UIKit

func JSONStringify(jsonObj: AnyObject) -> String {
    var e: NSError?
    let jsonData = NSJSONSerialization.dataWithJSONObject(
        jsonObj,
        options: NSJSONWritingOptions(0),
        error: &e)
    if (e != nil) {
        return ""
    } else {
        return NSString(data: jsonData!, encoding: NSUTF8StringEncoding)! as String
    }
}

extension Double {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }

    func isEmail() -> Bool {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, count(self))) != nil
    }
}

//Define colors
enum Colors {
    case primary
    case gray
    case success
    case warning
    case danger
    case info
    case black
    
    func textToUIColor() -> UIColor{
        switch (self) {
        case .primary:
            return UIColor(red: 0x1a/255, green: 0x9a/255, blue: 0xcb/255, alpha: 1.0)
        case .gray:
            return UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
        case .success:
            return UIColor(red: 0x08/255, green: 0x99/255, blue: 0x00/255, alpha: 1.0)
        case .warning:
            return UIColor(red: 0xbd/255, green: 0x62/255, blue: 0x00/255, alpha: 1.0)
        case .danger:
            return UIColor(red: 0xbb/255, green: 0x00/255, blue: 0x05/255, alpha: 1.0)
        case .info:
            return UIColor(red: 0x02/255, green: 0x57/255, blue: 0x77/255, alpha: 1.0)
        case .black:
            return UIColor(red: 0x00/255, green: 0x00/255, blue: 0x00/255, alpha: 1.0)
        }
    }
    
    func backgroundToUIColor() -> UIColor{
        switch (self) {
        case .success:
            return UIColor(red: 0xa1/255, green: 0xee/255, blue: 0x9d/255, alpha: 1.0)
        case .warning:
            return UIColor(red: 0xff/255, green: 0xd5/255, blue: 0xa8/255, alpha: 1.0)
        case .danger:
            return UIColor(red: 0xfe/255, green: 0xa8/255, blue: 0xaa/255, alpha: 1.0)
        case .info:
            return UIColor(red: 0x96/255, green: 0xca/255, blue: 0xde/255, alpha: 1.0)
        default:
            return UIColor.clearColor()
        }
    }
}
