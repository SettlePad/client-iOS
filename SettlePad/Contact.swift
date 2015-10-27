//
//  Contact.swift
//  SettlePad
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

class Contact: NSObject { //required for sections in viewcontroller with collation
    var name: String = "" //The name, as set by the contact itself (from the server)
	private(set) var friendlyName: String = "" //The name, as set by the user (from the server)
	var registered: Bool = false
	
	func setFriendlyName (newValue: String, updateServer: Bool) {
		let oldValue = friendlyName
		if identifiers.count > 0 && newValue != friendlyName && updateServer && propagatedToServer == true {
			HTTPWrapper.request("contacts/"+identifiers[0], method: .POST, parameters: ["friendly_name":newValue], authenticateWithUser: activeUser!,
				failure: { error in
					print(error.errorText)
					self.friendlyName = oldValue
				}
			)
			friendlyName = newValue
		}
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
	
	private(set) var autoAccept: AutoAccept = .Manual
	
	func setAutoAccept(newValue: AutoAccept, updateServer: Bool) {
		let oldValue = autoAccept
		if identifiers.count > 0 && newValue != autoAccept && updateServer && propagatedToServer == true {
			HTTPWrapper.request("contacts/"+identifiers[0], method: .POST, parameters: ["auto_accept":newValue.rawValue], authenticateWithUser: activeUser!,
				failure: { error in
					print(error.errorText)
					self.autoAccept = oldValue
				}
			)
			autoAccept = newValue
		}
	}
	
    private(set) var favorite: Bool = false

	func setFavorite (newValue: Bool, updateServer: Bool) {
		let oldValue = favorite
		if identifiers.count > 0 && newValue != favorite && updateServer && propagatedToServer == true {
			HTTPWrapper.request("contacts/"+identifiers[0], method: .POST, parameters: ["favorite":newValue], authenticateWithUser: activeUser!,
				failure: { error in
					print(error.errorText)
					self.favorite = oldValue
				}
			)
			favorite = newValue
		}
    }
	
    var identifiers = [String]()
	
	func updateServerIdentifier(newValue: String, success: (()->())? = nil, failure: ((error: SettlePadError)-> ())? = nil) {
		let oldValue = identifiers
		if newValue.isEmail() && oldValue.count > 0 && propagatedToServer == true {
			HTTPWrapper.request("contacts/"+oldValue[0], method: .POST, parameters: ["identifier":newValue], authenticateWithUser: activeUser!,
				success: {json in
					if let registered = json["data"]["registered"].bool {
						self.registered = registered
					}
					success?()
				},
				failure: { error in
					self.identifiers = oldValue
					failure?(error: error)
				}
			)
			identifiers = [newValue]
		}
	}
	
	private(set) var limits = [Limit]()
    var propagatedToServer: Bool = false //If false, we are sending it to the server
	
	var user: User
	
	init(name: String, friendlyName: String, registered: Bool, favorite: Bool, autoAccept: AutoAccept, identifiers: [String], propagatedToServer: Bool, user: User) {
		
        self.name = name
        self.friendlyName = friendlyName
		self.registered = registered
        self.favorite = favorite
		self.autoAccept = autoAccept
        self.identifiers = identifiers
        self.propagatedToServer = propagatedToServer
		self.user = user
		
		super.init()
    }
	
	init(json: JSON, propagatedToServer: Bool, user: User) {
		
		if let friendlyName = json["friendly_name"].string {
			self.friendlyName = friendlyName
		}

		var unregistered = true
		if let registered = json["registered"].int {
			if (registered > 0) {
				self.registered = true
				unregistered = false
			}
		}
		
		if let favorite = json["favorite"].int {
			if (favorite > 0) {
				self.favorite = true
			}
			
		}
		
		if let autoAcceptRaw = json["auto_accept"].int {
			if let autoAccept = AutoAccept(rawValue: autoAcceptRaw) {
				self.autoAccept = autoAccept
			}
		}
		
		for (_,subJson):(String, JSON) in json["identifiers"] {
			if let identifier = subJson["identifier"].string, active = subJson["active"].int {
				if active == 1 || unregistered {
					self.identifiers.append(identifier)
				}
			}
		}
		
		if let name = json["name"].string {
			self.name = name
		} else if self.identifiers.count > 0 {
			self.name = self.identifiers[0]
		}
		
		for (currencyString,subJson):(String, JSON) in json["limits"] {
			if let currency = Currency(rawValue: currencyString), limit = subJson.double {
				limits.append(Limit(currency: currency, limit: limit))
			}
		}
			
        self.propagatedToServer = propagatedToServer
		self.user = user
		
		super.init()

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
			HTTPWrapper.request("contacts/"+identifiers[0], method: .POST, parameters: ["limits":limitDict], authenticateWithUser: activeUser!,
				failure: { error in
					print(error.errorText)
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
			)
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
					HTTPWrapper.request("contacts/"+identifiers[0], method: .POST, parameters: ["limits":limitDict], authenticateWithUser: activeUser!,
						failure: { error in
							print(error.errorText)
							
							//roll back removal
							self.limits.append(old_limit)
						}
					)
				}
			}
		}
	}
	
	func deleteContact() {
		user.contacts.deleteContact(self)
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