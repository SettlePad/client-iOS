//
//  Balance.swift
//  UOless
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Balances {
	private(set) var balances = [Balance]()
	private(set) var currenciesSummary = [CurrencySummary]()
	private(set) var sortedCurrencies = [Currency]()
	
	init() {
		
	}
	
	func getBalancesForCurrency(currency: Currency)->[Balance] {
		return balances.filter { $0.currency == currency}
	}
	
	func getBalancesForContact(contact: Contact)->[Balance] {
		return balances.filter { $0.contact == contact}
	}

	func getSummaryForCurrency(currency: Currency)->CurrencySummary? {
		let returnArray = currenciesSummary.filter { $0.currency == currency}
		return returnArray.first
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
				self.currenciesSummary = []

				if let dataDict = data["data"] as? NSDictionary {
					if let connectionsDict = dataDict["connections"] as? Dictionary <String, [Dictionary <String, AnyObject>] > {
						for (currencyKey,balances) in connectionsDict {
							for details in balances {
								if let
									contactID = details["connection_id"] as? Int,
									contactName = details["connection_name"] as? String,
									balance = details["balance"] as? Double,
									unprocessed = details["unprocessed"] as? Bool
								{
									if let currency = Currency(rawValue: currencyKey) {
										if let contact = contacts.getContactByID(contactID) {
											self.balances.append(Balance(contact: contact, currency: currency, balance: balance, unprocessed: unprocessed))
										} else {
											//This ID does not exist yet, create it
											let contact = Contact(id: contactID, name: contactName, friendlyName: contactName, favorite: false, identifiers: [], registered: false)
											contacts.addContact(contact)
											self.balances.append(Balance(contact: contact, currency: currency, balance: balance, unprocessed: unprocessed))
										}
									} else {
										println("Unknown currency parsing balance: " + currencyKey)
									}
								}
							}
						}
					} else {
						println("no connections")
					}
				
					if let summaryDict = dataDict["summary"] as? Dictionary <String, Dictionary <String, AnyObject> > {
						for (currencyKey,details) in summaryDict {
							if let
								get = details["get"] as? Double,
								owe = details["owe"] as? Double,
								currency = Currency(rawValue: currencyKey)
							{
								if get != 0 || owe != 0 {
									self.currenciesSummary.append(CurrencySummary(currency: currency, get: get, owe: owe))
								}
							} else {
								println("Cannot parse summary for: "+currencyKey)
								
							}
						}
					} else {
						println("Cannot parse summary")
					}
					
				} else {
					//no balances, which is fine
				}
			}
			
			self.sortedCurrencies = []
			for currencySummary in self.currenciesSummary {
				self.sortedCurrencies.append(currencySummary.currency)
			}
			
			self.sortedCurrencies.sort({(left: Currency, right: Currency) -> Bool in
				left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
			requestCompleted()
		}
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
