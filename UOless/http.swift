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

    func login(username: String, password: String, loginCompleted : (succeeded: Bool, msg: String) -> ()) {
		//TODO: if logged in already, first log out

		request("login", method:"POST", formdata: ["provider":"password", "user":username, "password":password], secure:false) { (succeeded: Bool, data: NSDictionary) -> () in
			if(succeeded) {
				user = User(credentials: data as Dictionary, api: self)
				if user != nil {
					loginCompleted(succeeded: true, msg: user!.name)
					contacts.updateContacts()
				} else {
					loginCompleted(succeeded: false, msg: "Cannot initialize user class")
				}
			} else {
				if let msg = data["text"] as? String {
					loginCompleted(succeeded: false, msg: msg)
				} else {
					loginCompleted(succeeded: false, msg: "Unknown error")
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
		user!.wipe()
		user = nil
		
		//TODO: clear out transacitons, contacts etc.
	}
	
	func request(url : String, method: String, formdata : AnyObject?, secure: Bool, requestCompleted : (succeeded: Bool, data: NSDictionary) -> ()) -> NSURLSessionDataTask? {
		
		var proceedRequest = true
		var server = settingsDictionary!["server"]! as String

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
				//TODO: in future, one might choose to automatically log in at this point and then continuing the request
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
					//println("Cannot parse JSON: "+err!.debugDescription)
					if(error != nil) {
						//println(error.localizedFailureReason)
						//println(error.localizedRecoverySuggestion)
						
						//Rediculously, the localizedDescription is uninformative (i.e. The operation couldn’t be completed.). Do we have to test for all error codes :( ?
						//Also, see http://stackoverflow.com/questions/26741117/different-nserror-localizeddescription-between-ios-7-and-8
						
						if (error!.code == -1004) {
							requestCompleted(succeeded: false, data: ["code":"cannot_connect_to_server", "text":"Cannot connect to server", "function":"local"])
						} else {
							requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":error!.localizedDescription, "function":"local"])
						}
					} else {
						requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":err!.localizedDescription, "function":"local"])
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
							let status = (response as NSHTTPURLResponse).statusCode
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


