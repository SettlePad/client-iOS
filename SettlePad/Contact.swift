//
//  Contact.swift
//  SettlePad
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation

class Contact: NSObject { //required for sections in viewcontroller with collation
    var name: String //The name, as set by the contact itself (from the server)
	private(set) var friendlyName: String //The name, as set by the user (from the server)
	var registered: Bool
	
	func setFriendlyName (newValue: String, updateServer: Bool) {
		let oldValue = friendlyName
		if identifiers.count > 0 && newValue != friendlyName && updateServer && propagatedToServer == true {
			api.request("contacts/"+identifiers[0], method:"POST", formdata: ["friendly_name":newValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						print(error_msg)
					} else {
						print("Unknown error while setting friendly name")
					}
					self.friendlyName = oldValue
				}
			}
		}
		friendlyName = newValue
	}
	
	var resultingName: String {
		get {
			if friendlyName != "" {
				return friendlyName
			} else {
				return name
			}
		}
	}
	
	private(set) var autoAccept: AutoAccept
	
	func setAutoAccept(newValue: AutoAccept, updateServer: Bool) {
		let oldValue = autoAccept
		if identifiers.count > 0 && newValue != autoAccept && updateServer && propagatedToServer == true {
			api.request("contacts/"+identifiers[0], method:"POST", formdata: ["auto_accept":newValue.rawValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						print(error_msg)
					} else {
						print("Unknown error while setting auto accept")
					}
					self.autoAccept = oldValue
				}
			}
		}
		autoAccept = newValue
	}
	
    private(set) var favorite: Bool

	func setFavorite (newValue: Bool, updateServer: Bool) {
		let oldValue = favorite
		if identifiers.count > 0 && newValue != favorite && updateServer && propagatedToServer == true {
			api.request("contacts/"+identifiers[0], method:"POST", formdata: ["favorite":newValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						print(error_msg)
					} else {
						print("Unknown error while setting favorite")
					}
					self.favorite = oldValue
				}
			}
		}
        favorite = newValue
    }
	
    var identifiers = [String]()
	
	func updateServerIdentifier(newValue: String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		let oldValue = identifiers
		if newValue.isEmail() && oldValue.count > 0 && propagatedToServer == true {
			api.request("contacts/"+oldValue[0], method:"POST", formdata: ["identifier":newValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						requestCompleted(succeeded: false, error_msg: error_msg)
					} else {
						requestCompleted(succeeded: false, error_msg: "Unknown error while changing identifier")
					}
					self.identifiers = oldValue
				} else {
					if let registered = data["data"]?["registered"] as? Bool {
						self.registered = registered
					}
					requestCompleted(succeeded: true, error_msg: nil)
				}
				
			}
		}
		identifiers = [newValue]
	}
	
	private(set) var limits = [Limit]()
    var propagatedToServer: Bool //If false, we are sending it to the server
    
	init(name: String, friendlyName: String, registered: Bool, favorite: Bool, autoAccept: AutoAccept, identifiers: [String], propagatedToServer: Bool) {
        self.name = name
        self.friendlyName = friendlyName
		self.registered = registered
        self.favorite = favorite
		self.autoAccept = autoAccept
        self.identifiers = identifiers
        self.propagatedToServer = propagatedToServer
    }
    
    init(fromDict: NSDictionary = [:], propagatedToServer: Bool) {
        if let parsed = fromDict["name"] as? String {
            self.name = parsed
        } else {
            self.name = "Unknown"
        }
        
        if let parsed = fromDict["friendly_name"] as? String {
            self.friendlyName = parsed
        } else {
            self.friendlyName = ""
        }
		
		var registeredBool = false
		if let parsed = fromDict["registered"] as? Int {
			if (parsed > 0) {
				registeredBool = true
			} else {
				registeredBool = false
			}
		}
		self.registered = registeredBool //We are going to use this flag later on in identifiers
		
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
                        if active == 1 || registeredBool == false {
                            self.identifiers.append(identifier)
                        }
                    }
                }
            }
        }
		
        self.propagatedToServer = propagatedToServer
		
		if let contactLimits = fromDict["limits"] as? Dictionary <String, Double> {
			for (currencyString,limitDouble) in contactLimits {
				if let currency = Currency(rawValue: currencyString) {
					limits.append(Limit(currency: currency, limit: limitDouble))
				} else {
					print("Unknown currency: "+currencyString)
				}
			}
		}
    }
	
	func addLimit(currency: Currency, limit: Double) {
		var row: Int?
		for (index,limit) in limits.enumerate() {
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
		
		var limitDict = [String:Double]()
		for singleLimit in limits {
			limitDict[singleLimit.currency.rawValue] = singleLimit.limit
		}
		if identifiers.count > 0 && propagatedToServer == true {
			api.request("contacts/"+identifiers[0], method:"POST", formdata: ["limits":limitDict], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						print(error_msg)
					} else {
						print("Unknown error while adding limit")
					}
					//roll back addition
					
					for (index,limit) in self.limits.enumerate() {
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
		for (index,limit) in limits.enumerate() {
			if limit.currency == currency {
				row = index
			}
		}
		
		if row != nil {
			let old_limit = limits[row!]
			limits.removeAtIndex(row!)

			if updateServer && propagatedToServer == true {
				var limitDict = [String:Double]()
				for singleLimit in limits {
					limitDict[singleLimit.currency.rawValue] = singleLimit.limit
				}
				if identifiers.count > 0  && propagatedToServer == true {
					api.request("contacts/"+identifiers[0], method:"POST", formdata: ["limits":limitDict], secure:true)  { (succeeded: Bool, data: NSDictionary) -> () in
						if(!succeeded) {
							if let error_msg = data["text"] as? String {
								print(error_msg)
							} else {
								print("Unknown error while removing limit")
							}

							//roll back removal
							self.limits.append(old_limit)
						}
					}
				}
			}
		}
	}
	
	func deleteContact() {
		contacts.deleteContact(self)
	}
	
	func toDict() -> [String:AnyObject] {
		var limitDict = [String:Double]()
		for singleLimit in limits {
			limitDict[singleLimit.currency.rawValue] = singleLimit.limit
		}
		
		return [
			"favorite" : self.favorite,
			"auto_accept" : self.autoAccept.rawValue,
			"friendly_name" : self.friendlyName,
			"limits" : limitDict
		]
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