//
//  Contact.swift
//  UOless
//
//  Created by Rob Everhardt on 04/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Contact {
    var id: Int?
    var name: String
    var friendlyName: String
    var favorite: Bool
    var identifiers: [String]
    //TODO: autolimit to implement
    
    init(id: Int? = nil, name: String, friendlyName: String, favorite: Bool, identifiers: [String]) {
        self.id = id
        self.name = name
        self.friendlyName = friendlyName
        self.favorite = favorite
        self.identifiers = identifiers
    }
    
}