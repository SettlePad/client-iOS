//
//  User.swift
//  SettlePad
//
//  Created by Rob Everhardt on 15/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
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
                        print(error_msg)
                    } else {
                        print("Unknown error while setting name")
                    }
                }
            }
        }
    }

    var defaultCurrency: Currency! {
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
    
    init (id: Int, name: String, series:String, token: String, defaultCurrency: Currency, userIdentifiers: [UserIdentifier]){
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
            if Int(keychainObj.stringValue) == nil {
                return nil
            } else {
                self.id = Int(keychainObj.stringValue)
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
		var found = false
		if let defaultsStr = defaults.stringForKey("defaultCurrency") {
			if let currency = Currency(rawValue: defaultsStr) {
				self.defaultCurrency = currency
				found = true
			}
        }
		if found == false {
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
		
		var found = false
		if let strVal = credentials["default_currency"] as? String {
			if let currency = Currency(rawValue: strVal) {
				self.defaultCurrency = currency
				found = true
			}
		}
		if found == false {
			return nil
		}
		
        if let arrayVal = credentials["identifiers"] as? [[String:AnyObject]] {
            if arrayVal.count == 0 {
                print("Empty identifier array")
                return nil
            }
            
            
            for parsableIdentifier in arrayVal {
                if let identifier = parsableIdentifier["identifier"] as? String, source = parsableIdentifier["source"] as? String, verified = parsableIdentifier["verified"] as? Bool, primary = parsableIdentifier["primary"] as? Bool {
					self.userIdentifiers.append(UserIdentifier(identifier: identifier, source: source, verified: verified, pending: false, primary: primary))
                } else {
                    print("Cannot load identifier")
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
        defaults.setObject(defaultCurrency.rawValue, forKey: "defaultCurrency")
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
        defaults.setObject(nil, forKey: "defaultCurrency")
        defaults.setObject(nil, forKey: "userIdentifiers")
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
		api.verifyIdentifier(identifier.identifier, token: token) { (succeeded: Bool, error_msg: String?) -> () in
			identifier.pending = false
			if(succeeded) {
				identifier.verified = true
				for userIdentifier in self.userIdentifiers {
					userIdentifier.primary = false
				}
				identifier.primary = true
				self.save()
				requestCompleted(succeeded: true,error_msg: nil)
			} else {
				requestCompleted(succeeded: false,error_msg: error_msg!)
			}
		}
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

    func updateSettings(requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		api.request("settings", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				if let dataDict = data["data"] as? NSDictionary {
					if let strVal = dataDict["user_name"] as? String {
						self.name = strVal
					} else {
						print("Inparsable user name")
					}
					
					if let strVal = dataDict["default_currency"] as? String {
						if let currency = Currency(rawValue: strVal) {
							self.defaultCurrency = currency
						} else {
							print("Currency not on list")
						}
					} else {
						print("Inparsable currency")
					}
					
					if let arrayVal = dataDict["identifiers"] as? [[String:AnyObject]] {
						self.userIdentifiers = []
						if arrayVal.count == 0 {
							print("Empty identifier array")
						}
						
						for parsableIdentifier in arrayVal {
							if let identifier = parsableIdentifier["identifier"] as? String, source = parsableIdentifier["source"] as? String, verified = parsableIdentifier["verified"] as? Bool, primary = parsableIdentifier["primary"] as? Bool {
								self.userIdentifiers.append(UserIdentifier(identifier: identifier, source: source, verified: verified, pending: false, primary: primary))
							} else {
								print("Cannot load identifier")
							}
						}
					}
					
					self.save()
				} else {
					print("Cannot parse return as dictionary")
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
    
}