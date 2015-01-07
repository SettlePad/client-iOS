//
//  keychain.swift
//  UOless
//
//  Created by Rob Everhardt on 06/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit
import Security

class Keychain {
    
    class func save(key: String, data: NSData) -> Bool {
        let query: [String: AnyObject] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecValueData   : data ]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    class func load(key: String) -> NSData? {
        let query: [String: AnyObject] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecReturnData  : kCFBooleanTrue,
            kSecMatchLimit  : kSecMatchLimitOne ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef!.takeRetainedValue() as NSData)
        } else {
            return nil
        }
    }
    
    class func delete(key: String) -> Bool {
        let query: [String: AnyObject] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
    
    class func clear() -> Bool {
        let query: [String: AnyObject] = [ kSecClass : kSecClassGenericPassword ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
        
        return status == noErr
    }
    
}


extension String {
    public var dataValue: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    public var stringValue: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)!
    }
}
