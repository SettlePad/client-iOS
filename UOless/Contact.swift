//
//  Contact.swift
//  UOless
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Contact: NSObject { //required for sections in viewcontroller with collation
    var id: Int?
    var name: String
	var friendlyName: String {
		didSet (oldValue) {
			if id != nil {
				api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"friendly_name", "value":friendlyName], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(!succeeded) {
						if let error_msg = data["text"] as? String {
							println(error_msg)
						} else {
							println("Unknown error while setting friendly name")
						}
					}
				}
			}
		}
	}
    var favorite: Bool {
        didSet (oldValue) {
            if id != nil {
                api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"favorite", "value":favorite], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                    if(!succeeded) {
                        if let error_msg = data["text"] as? String {
                            println(error_msg)
                        } else {
                            println("Unknown error while setting favorite")
                        }
                    }
                }
            }
        }
    }
    
    
    
    var identifiers = [String]()
    private(set) var limits = [Limit]()
    var registered: Bool //Contacts that do not come from the UOless server but fmor the local address book get false. Of those, a subset will have a UOless account as well, but we cannot know without sharing the whole address book with the UOless server. And that we don't do
    
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
	
	func addLimit(currency: Currency, limit: Double, updateServer: Bool) {
		var row: Int?
		for (index,limit) in enumerate(limits) {
			if limit.currency == currency {
				row = index
			}
		}
	
		//only add if there is no limit for this currency yet
		if row == nil {
			limits.append(Limit(currency: currency, limit: limit))
		} else {
			limits[row!] = Limit(currency: currency, limit: limit)
		}
		
		if updateServer {

			api.request("autolimits/"+id!.description+"/"+currency.rawValue, method:"POST", formdata: ["auto_limit":limit], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						println(error_msg)
					} else {
						println("Unknown error while adding limit")
					}
					//TODO: roll back addition
				}
			}

		}
	}
	
	func removeLimit(currency: Currency, updateServer: Bool) {
		var row: Int?
		for (index,limit) in enumerate(limits) {
			if limit.currency == currency {
				row = index
			}
		}
		
		if row != nil {
			limits.removeAtIndex(row!)

			if updateServer {
				api.request("autolimits/"+id!.description+"/"+currency.rawValue, method:"POST", formdata: ["auto_limit":0.0], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(!succeeded) {
						if let error_msg = data["text"] as? String {
							println(error_msg)
						} else {
							println("Unknown error while removing limit")
						}
						//TODO: roll back removal
					}
				}
			}
		}

	}
}

class Limit {
	var currency: Currency
	var limit: Double
	
	init(currency: Currency, limit: Double) {
		self.currency = currency
		self.limit = limit
	}
}