//
//  Transaction.swift
//  SettlePad
//
//  Created by Rob Everhardt on 02/01/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

class Transaction {	
    var timeSent: NSDate = NSDate()
	var timeUpdated: NSDate = NSDate()
	var primaryIdentifierStr: String? = nil //Primary identifier of counterpart
	var usedIdentifierStr: String = "" //Identifier of counterpart used in transaction
	var name: String = ""
    var isSender: Bool = false
    var transactionID: Int? = nil
    var description: String = ""
    var currency: Currency = .EUR
    var amount: Double = 0
    var status: transactionStatus = .Processed
    var reduced: Bool = false
	var isRead: Bool = true
	
    var canBeCanceled: Bool {
        get {
            let now = NSDate()
            let minfourDate = now.dateByAddingTimeInterval(NSTimeInterval(-60*4)) //in seconds
            if
                status == .Draft || //if in draft
				(isSender == true && status == .AwaitingValidation) || //Has not been accepted yet
				(isSender == true && status == .Processed && timeSent.compare(minfourDate) != NSComparisonResult.OrderedAscending) //only for last five minutes in API, so show four
            {
                return true
            } else {
                return false
            }
        }
    }
    var canBeAccepted: Bool {
        get {
            if status == .AwaitingValidation && self.isSender == false {
                return true
            } else {
                return false
            }
        }
    }
	
	init(json: JSON) {
		if let statusRaw = json["status"].int {
			if let status = transactionStatus(rawValue: statusRaw){
				self.status = status
			}
		}
		
		if let timeSentString = json["time_sent"].string {
			let dateFormatter = NSDateFormatter()
			dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
			dateFormatter.timeZone = NSTimeZone.localTimeZone()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
			if let timeSent = dateFormatter.dateFromString(timeSentString) { //NSDate
				self.timeSent = timeSent
			}
		}
		
		if let timeUpdatedString = json["time_updated"].string {
			let dateFormatter = NSDateFormatter()
			dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
			dateFormatter.timeZone = NSTimeZone.localTimeZone()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
			if let timeUpdated = dateFormatter.dateFromString(timeUpdatedString) { //NSDate
				self.timeUpdated = timeUpdated
			}
		}
		
		if let name = json["counterpart_name"].string {
			self.name = name
		}
		
		if let primaryIdentifierStr = json["counterpart_primary_identifier"].string {
			self.primaryIdentifierStr = primaryIdentifierStr
		}
		
		if let usedIdentifierStr = json["counterpart_used_identifier"].string {
			self.usedIdentifierStr = usedIdentifierStr
		}
		
		if let isSenderInt = json["is_sender"].int {
			if isSenderInt == 1 {
				self.isSender = true
			}
		}
		
		if let transactionID = json["transaction_id"].int {
			self.transactionID = transactionID
		}
		
		if let description = json["description"].string {
			self.description = description
		}
		
		if let currencyRaw = json["status"].string {
			if let currency = Currency(rawValue: currencyRaw){
				self.currency = currency
			}
		}
		
		if let amount = json["amount"].double {
			self.amount = amount
		}
		
		if let reducedInt = json["reduced"].int {
			if reducedInt == 1 {
				self.reduced = true
			}
		}
		
		if let isReadInt = json["is_read"].int {
			if isReadInt == 0 {
				self.isRead = false
			}
		}
	}
	
	init(name: String, identifier: String, description: String, currency: Currency, amount: Double) {
        timeSent = NSDate()
        timeUpdated = NSDate()
        self.name = name
		self.primaryIdentifierStr = identifier
		self.usedIdentifierStr = identifier
        isSender = true
        transactionID = nil
        self.description = description
        self.currency = currency
        self.amount = amount
        status = .Draft
        reduced = false
		isRead = true //draft memos are always read
    }
}

enum transactionStatus: Int {
	case Processed = 0
	case AwaitingValidation = 1
	case CanceledOrRejected = 3
	case Draft = 4 //local only
	case Posted = 5 //local only
}