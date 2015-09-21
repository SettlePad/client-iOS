//
//  UserIdentifier.swift
//  SettlePad
//
//  Created by Rob Everhardt on 24/03/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation

class UserIdentifier : NSObject, NSCoding {
    var identifier: String
    var source: String
    var verified: Bool
	var pending: Bool
	
	init(identifier: String, source: String, verified: Bool, pending: Bool) {
        self.identifier = identifier
        self.source = source
        self.verified = verified
		self.pending = pending
    }
    
    
    //All below required for saving to and loading from NSUserDefaults
    required init?(coder decoder: NSCoder) {
		if let identifier = decoder.decodeObjectForKey("identifier") as? String {
			self.identifier = identifier
		} else {
			self.identifier = "unknown"
		}
		if let source = decoder.decodeObjectForKey("source") as? String {
			self.source = source
		} else {
			self.source = "email"
		}
		if let verified = decoder.decodeObjectForKey("verified") as? Bool {
			self.verified = verified
		} else {
			self.verified = false
		}
		if let pending = decoder.decodeObjectForKey("pending") as? Bool {
			self.pending = pending
		} else {
			self.pending = false
		}

    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(identifier, forKey: "identifier")
        coder.encodeObject(source, forKey: "source")
        coder.encodeObject(verified, forKey: "verified")
        coder.encodeObject(pending, forKey: "pending")
    }
}