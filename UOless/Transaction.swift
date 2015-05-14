//
//  Transaction.swift
//  UOless
//
//  Created by Rob Everhardt on 02/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Transaction {	
    var time_sent: NSDate
    var time_updated: NSDate
    var counterpart: Contact? //If linked to a contact
	var identifier: String? //If to be send, this contains an email address
    var is_sender: Bool
    var transaction_id: Int?
    var description: String
    var currency: Currency
    var amount: Double
    var status: transactionStatus
    var reduced: Bool

    var can_be_canceled: Bool {
        get {
            let now = NSDate()
            let minfourDate = now.dateByAddingTimeInterval(NSTimeInterval(-60*4)) //in seconds
            if
                status == .Draft || //if in draft
                (is_sender == true && (status == .Processed || status == .AwaitingValidation) && time_sent.compare(minfourDate) != NSComparisonResult.OrderedAscending) //only for last five minutes in API, so show four
            {
                return true
            } else {
                return false
            }
        }
    }
    var can_be_accepted: Bool {
        get {
            if status == .AwaitingValidation && self.is_sender == false {
                return true
            } else {
                return false
            }
        }
    }
    
    enum transactionStatus {
        case Draft
        case Posted
        case Processed
        case AwaitingValidation
        case CanceledOrRejected
    }
    
    init(fromDict: NSDictionary = [:]) {
        if let parsed = fromDict["status"] as? Int {
            //0 = processed, 1 = waiting for validation by recipient, 3 = canceled or rejected
            switch parsed {
            case 0:
                status = .Processed
            case 1:
                status = .AwaitingValidation
            case 3:
                status = .CanceledOrRejected
            default:
                println("Unknown status parameter")
                status = .Processed
            }
        } else {
            status = .Processed
            println("Failed to get status parameter")
        }
        
        if let time_sentString = fromDict["time_sent"] as? String {
            var dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let parsed = dateFormatter.dateFromString(time_sentString) { //NSDate
                time_sent = parsed
            } else {
                time_sent = NSDate()
                println("Failed to parse time_sent parameter")
            }
        } else {
            time_sent = NSDate()
            println("Failed to get time_sent parameter")
        }

        if let time_updatedString = fromDict["time_updated"] as? String {
            var dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let parsed = dateFormatter.dateFromString(time_updatedString) { //NSDate
                time_updated = parsed
            } else {
                time_updated = NSDate()
                println("Failed to parse time_updated parameter")
            }
        } else {
            time_updated = NSDate()
            println("Failed to get time_updated parameter")
        }
		
		if let
			counterpartID = fromDict["counterpart_id"] as? Int,
			counterpartName = fromDict["counterpart_name"] as? String,
			registeredInt = fromDict["recipient_registered"] as? Int
		{
			if let contact = contacts.getContactByID(counterpartID) {
				counterpart = contact
			} else {
				var recipientRegistered: Bool
				if (registeredInt == 1) {
					recipientRegistered = true
				} else {
					recipientRegistered = false
				}
				let contact = Contact(id: counterpartID, name: counterpartName, friendlyName: counterpartName, favorite: false, identifiers: [], registered: recipientRegistered)
				contacts.addContact(contact)
			}
		} else {
			counterpart = nil
            println("Failed to get counterpart")
        }

        
        if let parsed = fromDict["is_sender"] as? Int {
            if (parsed == 1) {
                is_sender = true
            } else {
                is_sender = false
            }
        } else {
            is_sender = false
            println("Failed to get is_sender parameter")
        }
        
        if let parsed = fromDict["transaction_id"] as? Int {
            transaction_id = parsed
        } else {
            transaction_id = nil
            println("Failed to get transaction_id parameter")
        }
        
        if let parsed = fromDict["description"] as? String {
            description = parsed
        } else {
            description = ""
            println("Failed to get description parameter")
        }
        
        if let parsed = fromDict["currency"] as? String {
			if let parsedCurrency = Currency(rawValue: parsed) {
				currency = parsedCurrency
			} else {
				currency = Currency.EUR
				println("Unknown currency parameter")
			}
        } else {
			currency = Currency.EUR
			println("Failed to get currency parameter")
        }
        
        if let parsed = fromDict["amount"] as? Double {
            amount = parsed
        } else {
            amount = 0
            println("Failed to get amount parameter")
        }
        
        if let parsed = fromDict["reduced"] as? Int {
            if (parsed == 1) {
                reduced = true
            } else {
                reduced = false
            }
        } else {
            reduced = false
            println("Failed to get reduced parameter")
        }
    }
    
	init(counterpart: Contact?, identifier: String, description: String, currency: Currency, amount: Double) {
        time_sent = NSDate()
        time_updated = NSDate()
        self.counterpart = counterpart
		self.identifier = identifier
        is_sender = true
        transaction_id = nil
        self.description = description
        self.currency = currency
        self.amount = amount
        status = .Draft
        reduced = false
    }
}