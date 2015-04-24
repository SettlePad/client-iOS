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
    var favorite: Bool {
        didSet (oldValue) {
            if id != nil {
                api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"favorite", "value":favorite], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
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
    }
    
    
    
    var identifiers = [String]()
    var limits = [String:Float]()
    var registered: Bool //Contacts that do not come from the UOless server but fmor the local address book get false. Of those, a subset will have a UOless account as well, but we cannot know without sharing the whole address book with the UOless server. And that we don't do
    
    //TODO: autolimit to implement
    init(id: Int? = nil, name: String, friendlyName: String, favorite: Bool, identifiers: [String], registered: Bool) {
        self.id = id
        self.name = name
        self.friendlyName = friendlyName
        self.favorite = favorite
        self.identifiers = identifiers
        self.registered = registered
    }
    
    init(fromDict: NSDictionary = [:], registered: Bool) {
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
        
        self.registered = registered
    }
}