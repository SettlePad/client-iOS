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
		//let timestamp = "\(Int(NSDate().timeIntervalSince1970))"
		
		if method == .POST {
			encoding = .JSON
		} else {
			encoding = .URL
		}

		var headers = [String:String]()

		if authenticateWithUser != nil {
			headers["X-USER-ID"] = authenticateWithUser!.id.description
			headers["X-SERIES"] = authenticateWithUser!.series
		}
		
		let request = Alamofire.request(method, server+url, parameters: parameters, encoding: encoding, headers: headers)

		#if DEBUG
			print("URL:" + server+url)
			print("Parameters:" + parameters.debugDescription)
			request.responseString {response in
				if let val = response.result.value {
					print("Return:" + val)
				}
			}
		#endif		
		
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