//
//  Balance.swift
//  UOless
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Balance {
	var contactID: Int //Not Contact class, because refreshing the contacts array will not lead to an update here
	var currency: Currency
	var balance: Float //Positive = get, negative = have to pay
	var unprocessed: Bool //if true, there are some transactions not yet canceled out, so there will probably be room for improvement, which can be seen when refreshing (canceling happens every 10 min)
	
	init(contactID: Int, currency: Currency, balance: Float, unprocessed: Bool) {
		self.contactID = contactID
		self.currency = currency
		self.balance = balance
		self.unprocessed = unprocessed
	}
}