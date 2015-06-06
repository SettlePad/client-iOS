//
//  http.swift
//  SettlePad
//
//  Created by Rob Everhardt on 11/12/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

/* See 
	http://jamesonquave.com/blog/developing-ios-apps-using-swift-part-3-best-practices/
	https://github.com/jquave/SwiftPOSTTutorial/blob/master/POSTTut/POSTTut/AppDelegate.swift
	http://www.raywenderlich.com/85578/first-core-data-app-using-swift
*/

import Foundation

class APIController {	
	func login(username: String, password: String, loginCompleted : (succeeded: Bool, msg: String, code: String) -> ()) {
		//if logged in already, first log out
		if user != nil {
			logout()
		}
		
		request("login", method:"POST", formdata: ["provider":"password", "user":username, "password":password], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				user = User(credentials: data as! Dictionary)
				if user != nil {
					contacts.updateContacts { (succeeded: Bool, error_msg: String?) -> () in
						loginCompleted(succeeded: true, msg: user!.name, code:"")
						contacts.updateAutoLimits(){}
					}
					
				} else {
					loginCompleted(succeeded: false, msg: "Cannot initialize user class", code: "")
				}
			} else {
				if let msg = data["text"] as? String, code = data["code"] as? String {
					loginCompleted(succeeded: false, msg: msg, code: code)
				} else {
					loginCompleted(succeeded: false, msg: "Unknown error", code: "unknown")
				}
			}
		}
	}
	
	func register(name: String, username: String, password: String, preferredCurrency: String, completed : (succeeded: Bool, error_msg: String?, userID: Int?) -> ()) {
		//if logged in already, first log out
		if user != nil {
			logout()
		}
		
		request("register/account", method:"POST", formdata: ["type":"email", "name":name, "identifier":username, "password":password, "primary_currency":preferredCurrency], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				if let userID = data["user_id"] as? Int {
					completed(succeeded: true, error_msg: nil, userID: userID)
				} else {
					completed(succeeded: false, error_msg: "Did not get a user ID. Try to log in manually", userID:nil)
				}
			} else {
				if let msg = data["text"] as? String {
					completed(succeeded: false, error_msg: msg, userID:nil)
				} else {
					completed(succeeded: false, error_msg: "Unknown error", userID:nil)
				}
			}
		}
	}
	
	func verifyIdentifier(identifierStr: String, token:String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		request("register/verify", method:"POST", formdata: ["identifier":identifierStr,"token":token], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
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
	
	func requestPasswordReset(identifierStr: String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		request("register/request_reset_password", method:"POST", formdata: ["identifier":identifierStr], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
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
	
	func resetPassword(identifierStr: String, passwordStr: String, tokenStr: String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		request("register/reset_password", method:"POST", formdata: ["identifier":identifierStr, "token":tokenStr, "password":passwordStr], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
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

	func registerAPNToken(tokenStr: String, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		request("apn", method:"POST", formdata: ["token":tokenStr], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
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
	
	func logout() {
		//Invalidate session at server
		request("logout", method:"POST", formdata: [:], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
			//println(data)
			if(!succeeded) {
				if let error_msg = data["text"] as? String {
					println(error_msg)
				} else {
					println("Unknown error while logging out")
				}
			}
		}
		self.clearUser() //Do not wait until logout is finished
	}
	
	func clearUser() {
		if user != nil {
			user!.wipe()
			user = nil
		}
		
		transactions.clear()
		contacts.clear()
	}
	
	func request(url : String, method: String, formdata : AnyObject?, secure: Bool, requestCompleted : (succeeded: Bool, data: NSDictionary) -> ()) -> NSURLSessionDataTask? {
		
		var proceedRequest = true
		var server = settingsDictionary!["server"]! as! String

		var request = NSMutableURLRequest(URL: NSURL(string: server+url)!)
        var session = NSURLSession.sharedSession()

		let timestamp = "\(Int(NSDate().timeIntervalSince1970))"
		request.setValue(timestamp, forHTTPHeaderField: "X-TIME")
		
		request.addValue("application/json", forHTTPHeaderField: "Accept")


		
		//For method = "GET", formdata = nil
		request.HTTPMethod = method
		var dataString = ""
		if let formdataDict: AnyObject = formdata {
			dataString = JSONStringify(formdataDict)
			let requestBodyData = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
			request.HTTPBody = requestBodyData
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		
		if (secure) {
			if (user != nil) {
				request.addValue(String(user!.id), forHTTPHeaderField: "X-USER-ID")
				request.addValue(user!.series, forHTTPHeaderField: "X-SERIES")

				//SHA 256 hash of X-SERIES + X-TIME + dataString (only for non-GET), with token as key
				var toHash = user!.series+timestamp
				if (method != "GET") {
					toHash += dataString
				}
				request.addValue(toHash.hmac(.SHA256, key: user!.token), forHTTPHeaderField: "X-HASH")
			} else {
				proceedRequest = false
				requestCompleted(succeeded: false, data: ["code":"local_login_error", "text":"Cannot perform request, not logged in", "function":"local"])
			}
		}
		
		
		if (proceedRequest) {
			var err: NSError?
			var task = session.dataTaskWithRequest(request, completionHandler:{(data : NSData!, response : NSURLResponse!, error : NSError!) in
		
				
				//println("Response: \(response)")
				let strData = NSString(data: data, encoding: NSUTF8StringEncoding)
				//println("Body: \(strData)")
				
				var err: NSError?
				var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary

				// We try to parse the JSON first.
				if(err != nil) {
					//Parsing resulted in an error. Next to that, we'll go for the error from the URL request itself, in the NSURLErrorDomain
					if(error != nil) {
						//println(error.localizedFailureReason)
						//println(error.localizedRecoverySuggestion)
						
						//Rediculously, the localizedDescription is uninformative (i.e. The operation couldn’t be completed.). Do we have to test for all error codes :( ?
						//Also, see http://stackoverflow.com/questions/26741117/different-nserror-localizeddescription-between-ios-7-and-8
						
						if (error!.code == -1004) {
							requestCompleted(succeeded: false, data: ["code":"cannot_connect_to_server", "text":"Cannot connect to server", "function":"local"])
						} else {
							requestCompleted(succeeded: false, data: ["code":"unknown", "text":error!.localizedDescription, "function":"local"])
						}
					} else {
						if strData != nil {
							requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":"JSON failed to parse: " + (strData! as String), "function":"local"])
						} else {
							requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":"JSON failed to parse", "function":"local"])
						}
					}
				} else {
					// The JSONObjectWithData constructor didn't return an error. But, we should still
					// check and make sure that json has a value using optional binding.
					if let parseJSON = json {
						//Check whether JSON contains an error key that the server sent us
						if let data = parseJSON["error"] as? NSDictionary {
							if let code = data["code"] as? String {
								if code == "unknown_series" {
									self.clearUser()
								}
							} else {
								println("Server sent back unknown error key")
								println(data)
							}
							
							requestCompleted(succeeded: false, data: data)
						} else {
							let status = (response as! NSHTTPURLResponse).statusCode
							if (status == 200) {
								requestCompleted(succeeded: true, data: parseJSON)
							} else {
								println("Server gave an error status, but no error key")
								println(parseJSON)
								requestCompleted(succeeded: false, data: parseJSON)
							}
						}
					} else {
						//No error in the json parsing, but still no json value. That's strange
						println("JSON has no value: \(strData)")
						requestCompleted(succeeded: false, data: ["code":"json_has_no_value", "text":"Error in parsing request: JSON has no value", "function":"local"])
					}
				}
			})
			task.resume()
			return task
		} else {
			return nil
		}
    }
}


