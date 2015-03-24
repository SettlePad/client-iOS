//
//  User.swift
//  UOless
//
//  Created by Rob Everhardt on 15/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation


class User {
    // The exclamation marks in the class variable declarations make sure we can use a failable class initializer, see https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html#//apple_ref/doc/uid/TP40014097-CH18-XID_339
    var id: Int!
    var series: String!
    var token: String!
    var userIdentifiers: [UserIdentifier] = [] //array of identifiers (for now, only email addresses)
    
    var name: String! {
        didSet (oldValue) {
            api.request("settings", method:"POST", formdata: ["name":name], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                if(!succeeded) {
                    if let error_msg = data["text"] as? String {
                        println(error_msg)
                    } else {
                        println("Unknown error while setting name")
                    }
                }
            }
        }
    }

    var defaultCurrency: String! {
        didSet {
            api.request("settings", method:"POST", formdata: ["default_currency":defaultCurrency], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                if(!succeeded) {
                    if let error_msg = data["text"] as? String {
                        println(error_msg)
                    } else {
                        println("Unknown error while setting currency")
                    }
                }
            }
        }
    }
    
    init (id: Int, name: String, series:String, token: String, defaultCurrency: String, userIdentifiers: [UserIdentifier]){
        self.id = id
        self.name = name
        self.series = series
        self.token = token
        self.defaultCurrency = defaultCurrency
        self.userIdentifiers = userIdentifiers
        save()
    }
    
    init?(){
        //Try to load from keychain and NSUserDefaults
        
        if let keychainObj = Keychain.load("user_id") {
            if keychainObj.stringValue.toInt() == nil {
                return nil
            } else {
                self.id = keychainObj.stringValue.toInt()
            }
        } else {
            return nil
        }
        
        if let keychainObj = Keychain.load("user_name") {
            self.name = keychainObj.stringValue
        } else {
            return nil
        }
        
        if let keychainObj = Keychain.load("series") {
            self.series = keychainObj.stringValue
        } else {
            return nil
        }

        if let keychainObj = Keychain.load("token") {
            self.token = keychainObj.stringValue
        } else {
            return nil
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let defaultsStr = defaults.stringForKey("default_currency") {
            self.defaultCurrency = defaultsStr
        } else {
            return nil
        }
        
        if let data = defaults.objectForKey("userIdentifiers") as? NSData {
            if let subdata = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [UserIdentifier] {
                self.userIdentifiers = subdata
            } else {
                return nil
            }
        } else {
            return nil
        }

        //TODO: also set something for identifiers
        //TODO: verify whether info (e.g. user_name, default_currency and contacts) are still up to date
    }
    
    init?(credentials: [String: AnyObject]){
        
        if let intVal = credentials["user_id"] as? Int {
            self.id = intVal
        } else {
            return nil
        }
        
        if let strVal = credentials["user_name"] as? String {
            self.name = strVal
        } else {
            return nil
        }
        
        if let strVal = credentials["series"] as? String {
            self.series = strVal
        } else {
            return nil
        }
        
        if let strVal = credentials["token"] as? String {
            self.token = strVal
        } else {
            return nil
        }
        
        if let strVal = credentials["default_currency"] as? String {
            self.defaultCurrency = strVal
        } else {
            return nil
        }
        
        if let arrayVal = credentials["identifiers"] as? [[String:AnyObject]] {
            if arrayVal.count == 0 {
                println("Empty identifier array")
                return nil
            }
            
            
            for parsableIdentifier in arrayVal {
                /*if let identifier = parsableIdentifier["identifier"] as? String, source = parsableIdentifier["source"] as? String, verified = parsableIdentifier["verified"] as? Bool {
                    self.identifiers.append(Identifier(identifier: identifier, source: source, verified: verified))
                } else {
                    println("Cannot load identifier")
                    return nil
                }*/
                //TODO: use more elegant code above when Xcode 6.3 is released

                switch (parsableIdentifier["identifier"], parsableIdentifier["source"], parsableIdentifier["verified"]) {
                case let (identifier as String, source as String, verified as Bool):
                    self.userIdentifiers.append(UserIdentifier(identifier: identifier, source: source, verified: verified))
                default:
                    println("Cannot load identifier")
                    return nil
                }
            }
        } else {
            return nil
        }
        
        save()
    }

    func save() {
        //Set keychain
        Keychain.save("user_id", data: String(id).dataValue)
        Keychain.save("token", data: token.dataValue)
        Keychain.save("series", data: series.dataValue)
        Keychain.save("user_name", data: name.dataValue)
        
        //Set NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(defaultCurrency, forKey: "default_currency")
        let data = NSKeyedArchiver.archivedDataWithRootObject(userIdentifiers)
        defaults.setObject(data, forKey: "userIdentifiers")
    }
    
    func wipe() {
        //Wipe keychain
        Keychain.delete("user_id")
        Keychain.delete("token")
        Keychain.delete("series")
        Keychain.delete("user_name")

        //Wipe NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "default_currency")
        defaults.setObject(nil, forKey: "userIdentifiers")

    }
}