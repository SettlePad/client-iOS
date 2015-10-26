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
	func request(url : String, method: String, formdata : AnyObject?, secure: Bool, requestCompleted : (succeeded: Bool, data: NSDictionary) -> ()) -> NSURLSessionDataTask? {
		
		var proceedRequest = true
		let server = settingsDictionary!["server"]! as! String

		let request = NSMutableURLRequest(URL: NSURL(string: server+url)!)
        let session = NSURLSession.sharedSession()

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
			if (activeUser != nil) {
				request.addValue(String(activeUser!.id), forHTTPHeaderField: "X-USER-ID")
				request.addValue(activeUser!.series, forHTTPHeaderField: "X-SERIES")

				//SHA 256 hash of X-SERIES + X-TIME + dataString (only for non-GET), with token as key
				var toHash = activeUser!.series+timestamp
				if (method != "GET") {
					toHash += dataString
				}
				request.addValue(toHash.hmac(.SHA256, key: activeUser!.token), forHTTPHeaderField: "X-HASH")
			} else {
				proceedRequest = false
				requestCompleted(succeeded: false, data: ["code":"local_login_error", "text":"Cannot perform request, not logged in", "function":"local"])
			}
		}
		
		
		if (proceedRequest) {
			//var err: NSError?
			let task = session.dataTaskWithRequest(request, completionHandler:{(data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
				if error != nil {
					NSLog("Error making request: " + error!.localizedDescription)
				} else {
					let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
					//println("Body: \(strData)")
					
					do {
						let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
						// The JSONObjectWithData constructor didn't return an error. But, we should still
						// check and make sure that json has a value using optional binding.
						if let parseJSON = json {
							//Check whether JSON contains an error key that the server sent us
							if let data = parseJSON["error"] as? NSDictionary {
								if let code = data["code"] as? String {
									if code == "unknown_series" {
										Login.clearUser()
									}
								} else {
									print("Server sent back unknown error key")
									print(data)
								}
								
								requestCompleted(succeeded: false, data: data)
							} else {
								let status = (response as! NSHTTPURLResponse).statusCode
								if (status == 200) {
									requestCompleted(succeeded: true, data: parseJSON)
								} else {
									print("Server gave an error status, but no error key")
									print(parseJSON)
									requestCompleted(succeeded: false, data: parseJSON)
								}
							}
						} else {
							//No error in the json parsing, but still no json value. That's strange
							print("JSON has no value: \(strData)")
							requestCompleted(succeeded: false, data: ["code":"json_has_no_value", "text":"Error in parsing request: JSON has no value", "function":"local"])
						}
					} catch let jsonError as NSError {
					//Parsing resulted in an error. Next to that, we'll go for the error from the URL request itself, in the NSURLErrorDomain
						if(error != nil) {
							//println(error.localizedFailureReason)
							//println(error.localizedRecoverySuggestion)
							
							//Rediculously, the localizedDescription is uninformative (i.e. The operation couldn’t be completed.). Do we have to test for all error codes :( ?
							//Also, see http://stackoverflow.com/questions/26741117/different-nserror-localizeddescription-between-ios-7-and-8
							
							if (jsonError.code == -1004) {
								requestCompleted(succeeded: false, data: ["code":"cannot_connect_to_server", "text":"Cannot connect to server", "function":"local"])
							} else {
								requestCompleted(succeeded: false, data: ["code":"unknown", "text":jsonError.localizedDescription, "function":"local"])
							}
						} else {
							if strData != nil {
								requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":"JSON failed to parse: " + (strData! as String), "function":"local"])
							} else {
								requestCompleted(succeeded: false, data: ["code":"cannot_parse_json", "text":"JSON failed to parse", "function":"local"])
							}
						}
					}
					catch
					{
						print("Fail: \(error)")
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


