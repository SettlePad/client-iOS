//
//  AlamofireWrapper.swift
//  SettlePad
//
//  Created by Rob Everhardt on 26/10/15.
//  Copyright © 2015 SettlePad. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class HTTPWrapper  {
	typealias SuccesHandler = (JSON?) -> Void
	typealias FailureHandler = (SettlePadError?) -> Void
	
	static func request(url: String, method: Alamofire.Method, parameters : [String : AnyObject]?, authenticate: Bool, success:SuccesHandler, failure:FailureHandler) -> Request {
		
		let server = settingsDictionary!["server"]! as! String
		//let request = NSMutableURLRequest(URL: NSURL(string: server + url)!)
		
		var encoding: Alamofire.ParameterEncoding
		let timestamp = "\(Int(NSDate().timeIntervalSince1970))"
		
		var toHash: String
		if user != nil {
			toHash = user!.series+timestamp
		} else {
			toHash = ""
		}
		if method == .POST {
			encoding = .JSON
			if user != nil && parameters != nil {
				toHash += JSONStringify(parameters!)
			}
		} else {
			encoding = .URL
		}

		var headers = [String:String]()
		headers["X-TIME"] = timestamp

		if user != nil && authenticate {
			headers["X-USER-ID"] = user!.id.description
			headers["X-SERIES"] = user!.series
			
			//TODO: when using SSL, the hash is not required any more
			headers["X-HASH"] = toHash.hmac(.SHA256, key: user!.token) //SHA 256 hash of X-SERIES + X-TIME + dataString (only for non-GET), with token as key
		}
		
		let request = Alamofire.request(method, server+url, parameters: parameters, encoding: encoding, headers: headers)

		request.validate()
		request.responseJSON {response in
			switch response.result {
			case .Success:
				if let rawJSON = response.result.value {
					let json = JSON(rawJSON)
					success(json["data"])
				} else {
					success(nil)
				}
			case .Failure(let error):
				print(error)
				if let rawJSON = response.result.value {
					let json = JSON(rawJSON)
					failure(SettlePadError(json: json, backupString: error.description))

					//Log out if needed
					if let errorCode = json["error"]["code"].string {
						if errorCode == "unknown_series" {
							user = nil
						}
					}
				} else {
					failure(SettlePadError(errorCode: "no_json_error", errorText: error.description))
				}
			}
		}
		
		return request
	}
}