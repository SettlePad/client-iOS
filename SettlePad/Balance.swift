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
	var iban: String //From server
	var currency: Currency
	var balance: Double //Positive = get, negative = have to pay
	var unprocessed: Bool //if true, there are some transactions not yet canceled out, so there will probably be room for improvement, which can be seen when refreshing (canceling happens every 10 min)
	
	init(identifierStr: String, name: String, iban: String, currency: Currency, balance: Double, unprocessed: Bool) {
		self.identifierStr = identifierStr
		self.name = name
		self.iban = iban
		self.currency = currency
		self.balance = balance
		self.unprocessed = unprocessed
	}
	
	func remind(success: (()->())? = nil, failure: ((error: SettlePadError)-> ())? = nil) {
		if activeUser!.iban == "" {
			failure?(error: SettlePadError(errorCode: "add_iban",errorText: "You should first set your IBAN in your profile"))
		} else {
			HTTPWrapper.request("remind/", method: .POST, parameters: ["identifier":identifierStr], authenticateWithUser: activeUser!,
				success: {json in
					success?()
				},
				failure: { error in
					failure?(error: error)
				}
			)
		}
	}
	
	func pay(success: (()->())? = nil, failure: ((error: SettlePadError)-> ())? = nil) {
		let transaction = Transaction(
			name: name,
			identifier: identifierStr,
			description: "Settlement of outstanding amount by bank transfer",
			currency: currency,
			amount: -1*balance
		)
		activeUser!.transactions.post(
			[transaction],
			success: {
				success?()
			},
			failure: { error in
				failure?(error: error)
			}
		)
	}
	
	var resultingName: String {
		get {
			if let identifier: Identifier? = activeUser!.contacts.getIdentifier(identifierStr) {
				return identifier!.resultingName
			} else {
				return name
			}
		}
	}
	
	var favorite: Bool {
		get {
			if let favoriteBool = activeUser!.contacts.getIdentifier(identifierStr)?.contact?.favorite {
				return favoriteBool
			} else {
				return false
			}
		}
	}
	
}