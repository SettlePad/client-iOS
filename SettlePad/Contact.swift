//
//  Contact.swift
//  SettlePad
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation

class Contact: NSObject { //required for sections in viewcontroller with collation
    var id: Int?
    var name: String
	
	private(set) var autoAccept: AutoAccept

	func setAutoAccept(newValue: AutoAccept, updateServer: Bool) {
		let oldValue = autoAccept
		if id != nil && newValue != autoAccept && updateServer {
			api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"auto_accept", "value":newValue.rawValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						println(error_msg)
					} else {
						println("Unknown error while setting auto accept")
					}
					self.autoAccept = oldValue
				}
			}
		}
		autoAccept = newValue
	}
	
	private(set) var friendlyName: String
	
	func setFriendlyName (newValue: String, updateServer: Bool) {
		let oldValue = friendlyName
		if id != nil && newValue != friendlyName && updateServer {
			api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"friendly_name", "value":newValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						println(error_msg)
					} else {
						println("Unknown error while setting friendly name")
					}
					self.friendlyName = oldValue
				}
			}
		}
		friendlyName = newValue
	}
	

	
    private(set) var favorite: Bool

	func setFavorite (newValue: Bool, updateServer: Bool) {
		let oldValue = favorite
		if id != nil && newValue != favorite && updateServer {
			api.request("contacts/"+id!.description, method:"POST", formdata: ["field":"favorite", "value":newValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						println(error_msg)
					} else {
						println("Unknown error while setting favorite")
					}
					self.favorite = oldValue
				}
			}
		}
        favorite = newValue
    }
	
    var identifiers = [String]()
    private(set) var limits = [Limit]()
    var registered: Bool //Contacts that do not come from the server but from the local address book get false. Of those, a subset will have an account as well, but we cannot know without sharing the whole address book with the server. And that we don't do
    
	init(id: Int? = nil, name: String, friendlyName: String, favorite: Bool, autoAccept: AutoAccept, identifiers: [String], registered: Bool) {
        self.id = id
        self.name = name
        self.friendlyName = friendlyName
        self.favorite = favorite
		self.autoAccept = autoAccept
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
		
		if let parsed = fromDict["auto_accept"] as? Int {
			if let autoAccept = AutoAccept(rawValue: parsed) {
				self.autoAccept = autoAccept
			} else {
				self.autoAccept = .Manual
			}
		} else {
			self.autoAccept = .Manual
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
		var old_limit: Limit?
		if row == nil {
			limits.append(Limit(currency: currency, limit: limit))
		} else {
			old_limit = limits[row!]
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
					//roll back addition
					
					for (index,limit) in enumerate(self.limits) {
						if limit.currency == currency {
							row = index
						}
					}
					
					if row != nil {
						if old_limit != nil {
							self.limits[row!] = old_limit!
						} else {
							self.limits.removeAtIndex(row!)
						}
					}

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
			var old_limit = limits[row!]
			limits.removeAtIndex(row!)

			if updateServer {
				api.request("autolimits/"+id!.description+"/"+currency.rawValue, method:"POST", formdata: ["auto_limit":0.0], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(!succeeded) {
						if let error_msg = data["text"] as? String {
							println(error_msg)
						} else {
							println("Unknown error while removing limit")
						}

						//roll back removal
						self.limits.append(old_limit)
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