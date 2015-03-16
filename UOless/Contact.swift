//
//  Contact.swift
//  UOless
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Contact {
    var id: Int?
    var name: String
    var friendlyName: String
    var favorite: Bool
    var identifiers = [String]()
    //TODO: autolimit to implement
    
    init(id: Int? = nil, name: String, friendlyName: String, favorite: Bool, identifiers: [String]) {
        self.id = id
        self.name = name
        self.friendlyName = friendlyName
        self.favorite = favorite
        self.identifiers = identifiers
    }
    
    init(fromDict: NSDictionary = [:]) {
        if let parsed = fromDict["id"] as? Int {
            self.id = parsed
        } else {
            self.id = nil
        }
        
        if let parsed = fromDict["name"] as? String {
            self.name = parsed
        } else {
            self.name = "Unknown"
        }
        
        if let parsed = fromDict["friendly_name"] as? String {
            self.friendlyName = parsed
        } else {
            self.friendlyName = self.name
        }
        
        if let parsed = fromDict["favorite"] as? Int {
            if (parsed > 0) {
                self.favorite = true
            } else {
                self.favorite = false
            }
        } else {
                self.favorite = false
        }
        
        if let parsed = fromDict["identifiers"] as? Array <Dictionary <String, AnyObject> > {
            for identifierObj in parsed {
                if let identifier = identifierObj["identifier"] as? String {
                    if let active = identifierObj["active"] as? Int {
                        if active == 1 {
                            self.identifiers.append(identifier)
                        }
                    }
                }
            }
        }
        
        //println(self.name+" added")
    }
}