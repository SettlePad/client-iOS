//
//  Balance.swift
//  UOless
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Balances {
	var balances = [Balance]()
	var currencies = Set<Currency>()
	var sortedCurrencies = [Currency]()
	
	init() {
		
	}
	
	func getBalancesForCurrency(currency: Currency)->[Balance] {
		return balances.filter { $0.currency == currency}
	}
	
	func getBalancesForContactID(contactID: Int)->[Balance] {
		return balances.filter { $0.contactID == contactID}
	}


	func updateBalances(requestCompleted: () -> ()) {
		api.request("balance/currencies", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
			if(!succeeded) {
				if let error_msg = data["text"] as? String {
					println(error_msg)
				} else {
					println("Unknown error while refreshing balances")
				}
			} else {
				
				self.balances = []
				self.currencies = []

				if let dataDict = data["data"] as? NSDictionary {
					if let connectionsDict = dataDict["connections"] as? Dictionary <String, Dictionary <String, AnyObject> > {
						for (currency,details) in connectionsDict {
							if let
								contactID = details["connection_id"] as? Int,
								currencyStr = details["currency"] as? String,
								balance = details["balance"] as? Float,
								unprocessed = details["unprocessed"] as? Bool
							{
								if let currency = Currency(rawValue: currencyStr) {
									self.balances.append(Balance(contactID: contactID, currency: currency, balance: balance, unprocessed: unprocessed))
									self.currencies.insert(currency)
								} else {
									println("Unknown currency parsing balance: " + currencyStr)
								}
								
							} else {
								println("Cannot parse balance")
							}
						}
					}
				} else {
					//no balances, which is fine
				}
			}
			
			self.sortedCurrencies = Array(self.currencies)

			self.sortedCurrencies.sort({(left: Currency, right: Currency) -> Bool in
				left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
			requestCompleted()
		}
	}
}
