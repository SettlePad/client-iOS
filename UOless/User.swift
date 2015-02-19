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
    
    var name: String! {
        didSet {
            api.request("settings", method:"POST", formdata: ["name":name], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                if(!succeeded) {
                    if let error_msg = data["text"] as? String {
                        println(error_msg)
                        //TODO: might reverse name or show error in view (also below)
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
    
    var api: APIController
    
    init (id: Int, name: String, series:String, token: String, defaultCurrency: String, api: APIController){
        self.id = id
        self.name = name
        self.series = series
        self.token = token
        self.defaultCurrency = defaultCurrency
        self.api = api
        
        save()
    }
    
    init?(api:APIController){
        self.api = api
        
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
        
        
        //TODO: verify whether info (e.g. user_name, default_currency and contacts) are still up to date
        //TODO: could also save the whole user class as NSData to NSUserDefaults. Would that also work with the reference to this apicontroller? Doubt that
    }
    
    init?(credentials: [String: String], api:APIController){
        self.api = api
        
        if let strVal = credentials["user_id"] {
            if strVal.toInt() == nil {
                return nil
            } else {
                self.id = strVal.toInt()!
            }
        } else {
            return nil
        }
        
        if credentials["user_name"] == nil {
            return nil
        } else {
            self.name = credentials["user_name"]!
        }
        
        if credentials["series"] == nil {
            return nil
        } else {
            self.series = credentials["series"]!
        }
        
        if credentials["token"] == nil {
            return nil
        } else {
            self.token = credentials["token"]!
        }
        
        if credentials["default_currency"] == nil {
            return nil
        } else {
            self.defaultCurrency = credentials["default_currency"]!
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
    }
    
}