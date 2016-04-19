//
//  User.swift
//  SettlePad
//
//  Created by Rob Everhardt on 15/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

class User {
    var id: Int = 0
    var series: String = ""
    var token: String = ""
    var userIdentifiers: [UserIdentifier] = [] //array of identifiers (for now, only email addresses)
	
	private(set) var name = ""
	private(set) var iban = ""
	private(set) var notifyByMail: Bool = true
	private(set) var defaultCurrency: Currency = .EUR
	
	func setName(name: String) {
		self.name = name
		HTTPWrapper.request("settings", method: .POST, parameters: ["name":name], authenticateWithUser: self,
			success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
    }
	
	func setIban(iban: String) {
		self.iban = iban
		HTTPWrapper.request("settings", method: .POST, parameters: ["iban":iban], authenticateWithUser: self,
			success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
	}
	
	func setNotifyByMail(notifyByMail: Bool) {
		self.notifyByMail = notifyByMail
		HTTPWrapper.request("settings", method: .POST, parameters: ["notify_by_mail":notifyByMail],authenticateWithUser: self,
			success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
	}

	func setDefaultCurrency(defaultCurrency: Currency) {
		self.defaultCurrency = defaultCurrency
		HTTPWrapper.request("settings", method: .POST, parameters: ["default_currency":defaultCurrency.rawValue], authenticateWithUser: self,
			success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
    }
	
	var contacts = Contacts()
    
	init (id: Int, name: String, iban:String, notifyByMail:Bool, series:String, token: String, defaultCurrency: Currency, userIdentifiers: [UserIdentifier]){
        self.id = id
        self.name = name
		self.iban = iban
		self.notifyByMail = notifyByMail
        self.series = series
        self.token = token
        self.defaultCurrency = defaultCurrency
        self.userIdentifiers = userIdentifiers
		self.contacts.user = self

		save()
    }

	var transactions=Transactions()
	var balances = Balances()
	
	init(json: JSON){
		if let id = json["user_id"].int {
			self.id = id
		}
		
		if let name = json["user_name"].string {
			self.name = name
		}
		
		if let iban = json["user_iban"].string {
			self.iban = iban
		}
		
		if let notifyByMail = json["user_notify_by_mail"].bool {
			self.notifyByMail = notifyByMail
		}
		
		if let series = json["series"].string {
			self.series = series
		}
		
		if let token = json["token"].string {
			self.token = token
		}
		
		if let defaultCurrencyRawValue = json["default_currency"].string{
			if let defaultCurrency = Currency(rawValue: defaultCurrencyRawValue){
				self.defaultCurrency = defaultCurrency
			}
		}
		
		for (_,subJson):(String, JSON) in json["identifiers"] {
			if let identifier = subJson["identifier"].string , source = subJson["source"].string, verified = subJson["verified"].bool, primary = subJson["primary"].bool {
				self.userIdentifiers.append(UserIdentifier(identifier: identifier, source: source, verified: verified, pending: false, primary: primary))
			} else {
				print("Cannot load identifier")
			}
		}
		
		self.contacts = Contacts()
		self.contacts.user = self
		
		save()

	}
	
    func save() {
        //Set keychain
        Keychain.save("user_id", data: String(id).dataValue)
        Keychain.save("token", data: token.dataValue)
        Keychain.save("series", data: series.dataValue)
        Keychain.save("user_name", data: name.dataValue)
		Keychain.save("user_iban", data: iban.dataValue)
        
        //Set NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(defaultCurrency.rawValue, forKey: "defaultCurrency")
        let data = NSKeyedArchiver.archivedDataWithRootObject(userIdentifiers)
        defaults.setObject(data, forKey: "userIdentifiers")
		defaults.setBool(notifyByMail, forKey: "notifyByMail")
    }
    
    static func wipe() {
        //Wipe keychain
        Keychain.delete("user_id")
        Keychain.delete("token")
        Keychain.delete("series")
        Keychain.delete("user_name")
		Keychain.delete("user_iban")

        //Wipe NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "defaultCurrency")
        defaults.setObject(nil, forKey: "userIdentifiers")
        defaults.setObject(nil, forKey: "notifyByMail")
    }
	
	static func loadFromKeychain() -> User? {
		var id: Int = 0
		var name: String = ""
		var iban: String = ""
		var series: String = ""
		var token: String = ""
		var userIdentifiers: [UserIdentifier] = []
		var defaultCurrency: Currency = .EUR
		
		if let keychainObj = Keychain.load("user_id") {
			if let intVal = Int(keychainObj.stringValue) {
				id = intVal
			}
		}
		
		if let keychainObj = Keychain.load("user_name") {
			name = keychainObj.stringValue
		} else {
			return nil
		}
		
		if let keychainObj = Keychain.load("user_iban") {
			iban = keychainObj.stringValue
		} else {
			return nil
		}
		
		if let keychainObj = Keychain.load("series") {
			series = keychainObj.stringValue
		} else {
			return nil
		}
		
		if let keychainObj = Keychain.load("token") {
			token = keychainObj.stringValue
		} else {
			return nil
		}
		
		let defaults = NSUserDefaults.standardUserDefaults()
		if let defaultsStr = defaults.stringForKey("defaultCurrency") {
			if let currency = Currency(rawValue: defaultsStr) {
				defaultCurrency = currency
			} else {
				return nil
			}
		} else {
			return nil
		}
		
		if let data = defaults.objectForKey("userIdentifiers") as? NSData {
			if let subdata = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [UserIdentifier] {
				userIdentifiers = subdata
			} else {
				return nil
			}
		} else {
			return nil
		}
		
		let notifyByMail = defaults.boolForKey("notifyByMail")
		
		return User(id: id, name: name, iban:iban, notifyByMail: notifyByMail, series: series, token: token, defaultCurrency: defaultCurrency, userIdentifiers: userIdentifiers)
	}
	
	func addIdentifier(email:String, password:String,success: ()->(), failure: (error: SettlePadError) -> ()) {
		self.userIdentifiers.append(UserIdentifier(identifier: email, source: "email", verified: false, pending: true, primary: false))
        HTTPWrapper.request("identifiers/new", method: .POST, parameters: ["identifier":email,"password":password,"type":"email"], authenticateWithUser: self,
			success: {_ in
				for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
					if self.userIdentifiers[index].identifier == email {
						self.userIdentifiers[index].pending = false
					}
				}
				self.save()
				success()
			},
			failure: { error in
				for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
					if self.userIdentifiers[index].identifier == email {
						self.userIdentifiers.removeAtIndex(index)
					}
				}
				failure(error: error)
			}
		)
    }
    
	func deleteIdentifier(identifier:UserIdentifier, success: ()->(), failure: (error: SettlePadError) -> ()) {
		for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
			if self.userIdentifiers[index].identifier == identifier.identifier {
				self.userIdentifiers.removeAtIndex(index)
			}
		}
		self.save()
		HTTPWrapper.request("identifiers/delete", method: .POST, parameters: ["identifier":identifier.identifier], authenticateWithUser: self,
			success: {json in
				if let primaryIdentifier = json["data"]["new_primary_identifier"].string {
					for userIdentifier in self.userIdentifiers {
						if userIdentifier.identifier == primaryIdentifier {
							userIdentifier.primary = true
						}
					}
				}
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
    }
    
	func resendToken(identifier:UserIdentifier,success: (()->())? = nil, failure: (error:SettlePadError)->()) {
        HTTPWrapper.request("register/resend_token", method: .POST, parameters: ["identifier":identifier.identifier,"user_id":self.id],
			success: {json in
				success?()
			},
			failure: { error in
				failure(error: error)
			}
		)
    }
	
	func verifyIdentifier(identifier:UserIdentifier, token:String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		identifier.pending = true
		Login.verifyIdentifier(identifier.identifier, token: token,
			success: {
				identifier.pending = false
				identifier.verified = true
				for userIdentifier in self.userIdentifiers {
					userIdentifier.primary = false
				}
				identifier.primary = true
				self.save()
				requestCompleted(succeeded: true,error_msg: nil)
			},
			failure: { error in
				identifier.pending = false
				requestCompleted(succeeded: false, error_msg: error.errorText)
			}
		)
	}

	func changePassword(identifier:UserIdentifier, password:String, success: (()->())? = nil, failure: (error:SettlePadError)->()) {
        HTTPWrapper.request("identifiers/change_pwd", method: .POST, parameters: ["identifier":identifier.identifier,"password":password], authenticateWithUser: self,
			success: {json in
				success?()
			},
			failure: { error in
				failure(error: error)
			}
		)
    }
	
	func setAsPrimary(identifier:UserIdentifier, success: ()->(), failure: (error: SettlePadError)-> ()) {
		let oldValue = identifier.primary
		var oldPrimary: UserIdentifier? = nil
		for userIdentifier in userIdentifiers {
			if userIdentifier.primary {
				oldPrimary = userIdentifier
			}
		}
		oldPrimary?.primary = false
		identifier.primary = true
		
		
		HTTPWrapper.request("identifiers/default", method: .POST, parameters: ["identifier":identifier.identifier], authenticateWithUser: self,
			success: {json in
				success()
			},
			failure: { error in
				identifier.primary = oldValue
				oldPrimary?.primary = true
				failure(error: error)
			}
		)
	}

	func getSettings(success: () -> (), failure: (error: SettlePadError) -> ()) {
		HTTPWrapper.request("settings", method: .GET, authenticateWithUser: self,
			success: { json in
				if let name = json["data"]["user_name"].string {
					self.name = name
				}
				
				if let iban = json["data"]["user_iban"].string {
					self.iban = iban
				}

				if let notifyByMail = json["data"]["user_notify_by_mail"].bool {
					self.notifyByMail = notifyByMail
				}
				
				if let rawCurrency = json["data"]["default_currency"].string {
					if let currency = Currency(rawValue: rawCurrency) {
						self.defaultCurrency = currency
					}
				}
				
				self.userIdentifiers = []
				for (_,subJson):(String, JSON) in json["data"]["identifiers"] {
					if let identifier = subJson["identifier"].string , source = subJson["source"].string, verified = subJson["verified"].bool, primary = subJson["primary"].bool {
						self.userIdentifiers.append(UserIdentifier(identifier: identifier, source: source, verified: verified, pending: false, primary: primary))
					} else {
						print("Cannot load identifier")
					}
				}
				self.save()
				
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
	
	func registerAPNToken(tokenStr: String, success : () -> (), failure: (error: SettlePadError)->()) {
		HTTPWrapper.request("apn", method: .POST, parameters: ["token":tokenStr], authenticateWithUser: self,
			success: { _ in
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
	
	func logout() {
		//Invalidate session at server
		HTTPWrapper.request("logout", method: .POST, authenticateWithUser: self, success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
		clearUser() //Do not wait until logout is finished
	}

}