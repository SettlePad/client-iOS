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
	typealias SuccesHandler = (JSON) -> Void
	typealias FailureHandler = (SettlePadError) -> Void
	
	static func request(url: String, method: Alamofire.Method, parameters : [String : AnyObject]? = nil, authenticateWithUser: User? = nil, success:SuccesHandler? = nil, failure:FailureHandler? = nil) -> Request {
		
		#if DEBUG
			let server = settingsDictionary!["server_debug"]! as! String
		#else
			let server = settingsDictionary!["server_prod"]! as! String
		#endif

		//let request = NSMutableURLRequest(URL: NSURL(string: server + url)!)
		
		var encoding: Alamofire.ParameterEncoding
		let timestamp = "\(Int(NSDate().timeIntervalSince1970))"
		
		var toHash: String
		if authenticateWithUser != nil {
			toHash = authenticateWithUser!.series+timestamp
		} else {
			toHash = ""
		}
		if method == .POST {
			encoding = .JSON
			if authenticateWithUser != nil && parameters != nil {
				toHash += JSONStringify(parameters!)
			}
		} else {
			encoding = .URL
		}

		var headers = [String:String]()
		headers["X-TIME"] = timestamp

		if authenticateWithUser != nil {
			headers["X-USER-ID"] = authenticateWithUser!.id.description
			headers["X-SERIES"] = authenticateWithUser!.series
			
			//TODO: when using SSL, the hash is not required any more
			headers["X-HASH"] = toHash.hmac(.SHA256, key: authenticateWithUser!.token) //SHA 256 hash of X-SERIES + X-TIME + dataString (only for non-GET), with token as key
		}
		
		let request = Alamofire.request(method, server+url, parameters: parameters, encoding: encoding, headers: headers)

		print("URL:" + server+url)
		print("Parameters:" + parameters.debugDescription)
		request.responseString {response in
			if let val = response.result.value {
				print("Return:" + val)
			}
		}
		
		request.responseJSON {response in
			switch response.result {
			case .Success:
				if let rawJSON = response.result.value {
					let json = JSON(rawJSON)
					if json["error"].exists() {
						failure?(SettlePadError(json: json))
					} else {
						success?(json)
					}
				} else {
					success?(JSON([])) //Empty
				}
			case .Failure(let error):
				print(error)
				failure?(SettlePadError(errorCode: "no_json_error", errorText: error.description))
			}
		}
		
		return request
	}
}