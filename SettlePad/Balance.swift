//
//  Balance.swift
//  SettlePad
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation

class Balance {
	var identifierStr: String
	var name: String //From server
	var currency: Currency
	var balance: Double //Positive = get, negative = have to pay
	var unprocessed: Bool //if true, there are some transactions not yet canceled out, so there will probably be room for improvement, which can be seen when refreshing (canceling happens every 10 min)
	
	init(identifierStr: String, name: String, currency: Currency, balance: Double, unprocessed: Bool) {
		self.identifierStr = identifierStr
		self.name = name
		self.currency = currency
		self.balance = balance
		self.unprocessed = unprocessed
	}
}