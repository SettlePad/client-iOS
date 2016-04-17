//
//  Login.swift
//  SettlePad
//
//  Created by Rob Everhardt on 26/10/15.
//  Copyright © 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
var settingsDictionary = NSDictionary(contentsOfFile: documentList!)

var activeUser: User? = User.loadFromKeychain()

func clearUser() {
	User.wipe()
	activeUser = nil
}

class Login {
	static func login(username: String, password: String, success : (user: User) -> (), failure: (error: SettlePadError) -> ()) {
		
		HTTPWrapper.request("login", method: .POST, parameters: ["provider":"password", "user":username, "password":password],
			success: { json in
				let user = User(json: json)
				user.contacts.updateContacts (
					{
						success(user: user)
					},
					failure: {error in
						success(user: user)
					}
				)
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
	
	static func register(name: String, username: String, password: String, preferredCurrency: String, success: (userID: Int) -> (),failure: (error: SettlePadError) -> ()) {
		HTTPWrapper.request("register/account", method: .POST, parameters: ["type":"email", "name":name, "identifier":username, "password":password, "primary_currency":preferredCurrency],
			success: { json in
				if let userID = json["user_id"].int {
					success(userID: userID)
				} else {
					failure(error: SettlePadError(errorCode: "no_id_returned", errorText: "Did not get a user ID. Try to log in manually"))
				}
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
	
	static func verifyIdentifier(identifierStr: String, token:String, success : () -> (), failure: (error: SettlePadError)->()) {
		
		HTTPWrapper.request("register/verify", method: .POST, parameters: ["identifier":identifierStr,"token":token],
			success: { _ in
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
		
	}
	
	static func requestPasswordReset(identifierStr: String, success : () -> (), failure: (error: SettlePadError)->()) {
		HTTPWrapper.request("register/request_reset_password", method: .POST, parameters: ["identifier":identifierStr],
			success: { _ in
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
	
	static func resetPassword(identifierStr: String, passwordStr: String, tokenStr: String, success : () -> (), failure: (error: SettlePadError)->()) {
		HTTPWrapper.request("register/reset_password", method: .POST, parameters: ["identifier":identifierStr, "token":tokenStr, "password":passwordStr],
			success: { _ in
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
}