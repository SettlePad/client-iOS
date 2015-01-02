//
//  http.swift
//  UOless
//
//  Created by Rob Everhardt on 11/12/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

/* See 
	http://jamesonquave.com/blog/developing-ios-apps-using-swift-part-3-best-practices/
	https://github.com/jquave/SwiftPOSTTutorial/blob/master/POSTTut/POSTTut/AppDelegate.swift
	http://www.raywenderlich.com/85578/first-core-data-app-using-swift
*/

import Foundation


class APIController {
	var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
	var settingsDictionary: AnyObject? = nil

	var userDictionary = [String: String]()
	var logged_in: Bool = false
	
	init() {
		//load plist data
		settingsDictionary = NSDictionary(contentsOfFile: documentList!)
		
		//TODO: load user data from core data
	}
	
    func login(username: String, password: String, loginCompleted : (succeeded: Bool, msg: String) -> ()) {
		//TODO: if logged in already, first log out
		
		request("login", method:"POST", formdata: ["provider":"password", "user":username, "password":password], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				var expectedKeys: [String] = ["series", "token","user_id","user_name","default_currency"]
				self.logged_in = true
				for expectedKey in expectedKeys {
					if let keyValue = data[expectedKey] as? String {
						self.userDictionary[expectedKey] = keyValue
					} else {
						self.logged_in = false
					}
				}

				if (self.logged_in == true) {
					loginCompleted(succeeded: succeeded, msg: self.userDictionary["user_name"]!)
				}
			} else {
				if let msg = data["text"] as? String {
					loginCompleted(succeeded: succeeded, msg: msg)
				} else {
					loginCompleted(succeeded: succeeded, msg: "Unknown error")
				}
			}
		}
	}
	
	func is_loggedIn()-> Bool {
		return logged_in
	}
	
	func get_userID() -> String {
		return userDictionary["user_id"] ?? "" //Where "" is the default
	}
	
	func get_userName() -> String {
		return userDictionary["user_name"] ?? "" //Where "" is the default
	}

	func get_defaultCurrency() -> String {
		return userDictionary["default_currency"] ?? "" //Where "" is the default
	}
	
	func request(url : String, method: String, formdata : NSDictionary?, secure: Bool, requestCompleted : (succeeded: Bool, data: NSDictionary) -> ()) {

		var proceedRequest = true
		
		var server = self.settingsDictionary!["server"]! as String

		var request = NSMutableURLRequest(URL: NSURL(string: server+url)!)
        var session = NSURLSession.sharedSession()

		let timestamp = "\(Int(NSDate().timeIntervalSince1970))"
		request.setValue(timestamp, forHTTPHeaderField: "X-TIME")
		
		request.addValue("application/json", forHTTPHeaderField: "Accept")


		
		//For method = "GET", formdata = nil
		request.HTTPMethod = method
		var dataString = ""
		if let formdataDict = formdata {
			dataString = JSONStringify(formdataDict)
			let requestBodyData = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
			request.HTTPBody = requestBodyData
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		
		if (secure) {
			if (self.logged_in == true) {
				request.addValue(self.userDictionary["user_id"]!, forHTTPHeaderField: "X-USER-ID")
				request.addValue(self.userDictionary["series"]!, forHTTPHeaderField: "X-SERIES")

				//SHA 256 hash of X-SERIES + X-TIME + dataString (only for non-GET), with token as key
				var toHash = self.userDictionary["series"]!+timestamp
				if (method != "GET") {
					toHash += dataString
				}
				request.addValue(toHash.hmac(.SHA256, key: self.userDictionary["token"]!), forHTTPHeaderField: "X-HASH")
			} else {
				proceedRequest = false
				requestCompleted(succeeded: false, data: ["code":"local_login_error", "text":"Cannot perform request, not logged in", "function":"local"])
				//In future, one might choose to automatically log in at this point and then continuing the request
			}
		}
		
		
		if (proceedRequest) {
			var err: NSError?
			var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
				//println("Response: \(response)")
				var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
				//println("Body: \(strData)")
				var err: NSError?
				var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary

				// Did the JSONObjectWithData constructor return an error? If so, log the error to the console
				if(err != nil) {
					let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
					println("Error could not parse JSON: '\(jsonStr)'")
					requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":err!.localizedDescription, "function":"local"])
				}
				else {
					// The JSONObjectWithData constructor didn't return an error. But, we should still
					// check and make sure that json has a value using optional binding.
					if let parseJSON = json {
						if let data = parseJSON["error"] as? NSDictionary {
							requestCompleted(succeeded: false, data: data)
						} else {
							let status = (response as NSHTTPURLResponse).statusCode
							if (status == 200) {
								requestCompleted(succeeded: true, data: parseJSON)
							} else {
								requestCompleted(succeeded: false, data: parseJSON)
							}
						}
					}
					else {
						// Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
						let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
						println("Error could not parse JSON: \(jsonStr)")
						requestCompleted(succeeded: false, data: ["code":"local_unknown_error", "text":"Unknown local error", "function":"local"])
					}
				}
			})
			task.resume()
		}
    }
}


