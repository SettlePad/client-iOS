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
    var name: String = "" {
        didSet (oldValue) {
            api.request("settings", method:"POST", formdata: ["name":name], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                if(!succeeded) {
                    if let error_msg = data["text"] as? String {
                        print(error_msg)
                    } else {
                        print("Unknown error while setting name")
                    }
                }
            }
        }
    }

    var defaultCurrency: Currency = .EUR {
        didSet {
            api.request("settings", method:"POST", formdata: ["default_currency":defaultCurrency.rawValue], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                if(!succeeded) {
                    if let error_msg = data["text"] as? String {
                        print(error_msg)
                    } else {
                        print("Unknown error while setting currency")
                    }
                }
            }
        }
    }
	
	var contacts = Contacts()
    
    init (id: Int, name: String, series:String, token: String, defaultCurrency: Currency, userIdentifiers: [UserIdentifier]){
        self.id = id
        self.name = name
        self.series = series
        self.token = token
        self.defaultCurrency = defaultCurrency
        self.userIdentifiers = userIdentifiers
		self.contacts.user = self

		save()
    }

	
	init(json: JSON){
		if let id = json["user_id"].int {
			self.id = id
		}
		
		if let name = json["user_name"].string {
			self.name = name
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
        
        //Set NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(defaultCurrency.rawValue, forKey: "defaultCurrency")
        let data = NSKeyedArchiver.archivedDataWithRootObject(userIdentifiers)
        defaults.setObject(data, forKey: "userIdentifiers")
    }
    
    static func wipe() {
        //Wipe keychain
        Keychain.delete("user_id")
        Keychain.delete("token")
        Keychain.delete("series")
        Keychain.delete("user_name")

        //Wipe NSUserdefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "defaultCurrency")
        defaults.setObject(nil, forKey: "userIdentifiers")
    }
	
	static func loadFromKeychain() -> User? {
		var id: Int = 0
		var name: String = ""
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
		
		return User(id: id, name: name, series: series, token: token, defaultCurrency: defaultCurrency, userIdentifiers: userIdentifiers)
	}
	
    func addIdentifier(email:String, password:String,requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		self.userIdentifiers.append(UserIdentifier(identifier: email, source: "email", verified: false, pending: true, primary: false))
        api.request("identifiers/new", method:"POST", formdata: ["identifier":email,"password":password,"type":"email"], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(succeeded) {
				for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
					if self.userIdentifiers[index].identifier == email {
						self.userIdentifiers[index].pending = false
					}
				}
                self.save()
                requestCompleted(succeeded: true,error_msg: nil)
            } else {
				for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
					if self.userIdentifiers[index].identifier == email {
						self.userIdentifiers.removeAtIndex(index)
					}
				}
                if let msg = data["text"] as? String {
                    requestCompleted(succeeded: false,error_msg: msg)
                } else {
                    requestCompleted(succeeded: false,error_msg: "Unknown")
                }
            }
        }
    }
    
    func deleteIdentifier(identifier:UserIdentifier, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		for index in (self.userIdentifiers.count - 1).stride(through: 0, by: -1) {
			if self.userIdentifiers[index].identifier == identifier.identifier {
				self.userIdentifiers.removeAtIndex(index)
			}
		}
		self.save()
		api.request("identifiers/delete", method:"POST", formdata: ["identifier":identifier.identifier], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(succeeded) {
				if let primaryIdentifier = data["data"]?["new_primary_identifier"] as? String {
					for userIdentifier in self.userIdentifiers {
						if userIdentifier.identifier == primaryIdentifier {
							userIdentifier.primary = true
						}
					}
				}
                requestCompleted(succeeded: true,error_msg: nil)
            } else {
                if let msg = data["text"] as? String {
                    requestCompleted(succeeded: false,error_msg: msg)
                } else {
                    requestCompleted(succeeded: false,error_msg: "Unknown")
                }
            }
        }
    }
    
    func resendToken(identifier:UserIdentifier,requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
        api.request("register/resend_token", method:"POST", formdata: ["identifier":identifier.identifier,"user_id":self.id], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
            if(succeeded) {
                requestCompleted(succeeded: true,error_msg: nil)
            } else {
                if let msg = data["text"] as? String {
                    requestCompleted(succeeded: false,error_msg: msg)
                } else {
                    requestCompleted(succeeded: false,error_msg: "Unknown")
                }
            }
        }
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

    func changePassword(identifier:UserIdentifier, password:String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {

        api.request("identifiers/change_pwd", method:"POST", formdata: ["identifier":identifier.identifier,"password":password], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(succeeded) {
                requestCompleted(succeeded: true,error_msg: nil)
            } else {
                if let msg = data["text"] as? String {
                    requestCompleted(succeeded: false,error_msg: msg)
                } else {
                    requestCompleted(succeeded: false,error_msg: "Unknown")
                }
            }
        }
    }
	
	func setAsPrimary(identifier:UserIdentifier, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		let oldValue = identifier.primary
		var oldPrimary: UserIdentifier? = nil
		for userIdentifier in userIdentifiers {
			if userIdentifier.primary {
				oldPrimary = userIdentifier
			}
		}
		oldPrimary?.primary = false
		identifier.primary = true
		api.request("identifiers/default", method:"POST", formdata: ["identifier":identifier.identifier], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				requestCompleted(succeeded: true,error_msg: nil)
			} else {
				identifier.primary = oldValue
				oldPrimary?.primary = true
				if let msg = data["text"] as? String {
					requestCompleted(succeeded: false,error_msg: msg)
				} else {
					requestCompleted(succeeded: false,error_msg: "Unknown")
				}
			}
		}
	}

	func getSettings(success: () -> (), failure: (error: SettlePadError) -> ()) {
		HTTPWrapper.request("settings", method: .GET, parameters: nil, authenticateWithUser: self,
			success: { json in
				if let name = json["data"]["user_name"].string {
					self.name = name
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
		HTTPWrapper.request("logout", method: .POST, parameters: nil, authenticateWithUser: self, success: {_ in },
			failure: { error in
				print(error.errorText)
			}
		)
		Login.clearUser() //Do not wait until logout is finished
	}

}