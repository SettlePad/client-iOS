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
    
    init(identifier: String, source: String, verified: Bool) {
        self.identifier = identifier
        self.source = source
        self.verified = verified
    }
    
    
    //All below required for saving to and loading from NSUserDefaults
    required init(coder decoder: NSCoder) {
        identifier = decoder.decodeObjectForKey("identifier") as! String
        source = decoder.decodeObjectForKey("source") as! String
        verified = decoder.decodeObjectForKey("verified") as! Bool
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(identifier, forKey: "identifier")
        coder.encodeObject(source, forKey: "source")
        coder.encodeObject(verified, forKey: "verified")
    }
}