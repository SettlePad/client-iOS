//
//  Error.swift
//  SettlePad
//
//  Created by Rob Everhardt on 26/10/15.
//  Copyright © 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

struct SettlePadError {
	var errorCode: String = "unknown_error"
	var errorText: String = "Unknown Error"
	
	init(json: JSON) {
		if let errorCode = json["error"]["code"].string {
			self.errorCode = errorCode
		}
		
		if let errorText = json["error"]["text"].string {
			self.errorText = errorText
		}
	}
	
	init(errorCode: String, errorText: String) {
		self.errorCode = errorCode
		self.errorText = errorText
	}

}