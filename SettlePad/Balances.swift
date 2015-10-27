//
//  Balance.swift
//  SettlePad
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

class Balances {
	private(set) var balances = [Balance]()
	private(set) var currenciesSummary = [CurrencySummary]()
	private(set) var sortedCurrencies = [Currency]()
	
	init() {
		
	}
	
	func getBalancesForCurrency(currency: Currency)->[Balance] {
		return balances.filter { $0.currency == currency}
	}
	
	/*func getBalancesForContact(contact: Contact)->[Balance] {
		return balances.filter { $0.contact == contact}
	}*/

	func getSummaryForCurrency(currency: Currency)->CurrencySummary? {
		let returnArray = currenciesSummary.filter { $0.currency == currency}
		return returnArray.first
	}
	
	func updateBalances(success: ()->(), failure: (error:SettlePadError)->()) {
		HTTPWrapper.request("balance/currencies", method: .GET, authenticateWithUser: activeUser!,
			success: {json in
				self.balances = []
				self.currenciesSummary = []
				
				for (rawCurrency,connectionJSON):(String, JSON) in json["data"]["connections"] {
					for (_,connection):(String, JSON) in connectionJSON {
						if let
							contactIdentifier = connection["primary_identifier"].string,
							contactName = connection["name"].string,
							balance = connection["balance"].double,
							unprocessed = connection["unprocessed"].bool,
							currency = Currency(rawValue: rawCurrency)
						{
						
							self.balances.append(Balance(identifierStr: contactIdentifier, name: contactName, currency: currency, balance: balance, unprocessed: unprocessed))
						}
					}
				}
				
				for (rawCurrency,balance):(String, JSON) in json["data"]["summary"] {
					if let
						get = balance["get"].double,
						owe = balance["owe"].double,
						currency = Currency(rawValue: rawCurrency)
					{
						if get != 0 || owe != 0 {
							self.currenciesSummary.append(CurrencySummary(currency: currency, get: get, owe: owe))
						}
					}
				}

				self.sortedCurrencies = []
				for currencySummary in self.currenciesSummary {
					self.sortedCurrencies.append(currencySummary.currency)
				}
				
				self.sortedCurrencies.sortInPlace({(left: Currency, right: Currency) -> Bool in
					left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
				
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
	}
}

class CurrencySummary {
	var currency: Currency
	var get: Double
	var owe: Double
	var balance: Double
	
	init (currency: Currency, get: Double, owe: Double) {
		self.currency = currency
		self.get = get
		self.owe = owe
		self.balance = get+owe
	}
}
