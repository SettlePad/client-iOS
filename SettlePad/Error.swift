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
	var errorCode: String?
	var errorText: String?
	
	init(json: JSON, backupString: String) {
		if let errorCode = json["error"]["code"].string {
			self.errorCode = errorCode
		} else {
			self.errorCode = ""
		}
		
		if let errorText = json["error"]["text"].string {
			self.errorText = errorText
		} else {
			self.errorText = backupString
		}
	}
	
	init(errorCode: String, errorText: String) {
		self.errorCode = errorCode
		self.errorText = errorText
	}

}