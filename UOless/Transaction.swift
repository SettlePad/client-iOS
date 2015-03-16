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
    var counterpart_name: String
    var counterpart_id: Int?
    var recipient_registered: Bool
    var is_sender: Bool
    var transaction_id: Int?
    var description: String
    var currency: String
    var amount: Double
    var status: transactionStatus
    var reduced: Bool
    var is_read: Bool

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
        
        if let parsed = fromDict["counterpart_name"] as? String {
            counterpart_name = parsed
        } else {
            counterpart_name = ""
            println("Failed to get counterpart_name parameter")
        }
        
        if let parsed = fromDict["counterpart_id"] as? Int {
            counterpart_id = parsed
        } else {
            counterpart_id = nil
            println("Failed to get counterpart_id parameter")
        }
        
        if let parsed = fromDict["recipient_registered"] as? Int {
            if (parsed == 1) {
                recipient_registered = true
            } else {
                recipient_registered = false
            }
        } else {
            recipient_registered = false
            println("Failed to get recipient_registered parameter")
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
            currency = parsed
        } else {
            currency = ""
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

        is_read = false
    }
    
    init(counterpart_name: String, description: String, currency: String, amount: Double) {
        time_sent = NSDate()
        time_updated = NSDate()
        self.counterpart_name = counterpart_name
        counterpart_id = nil
        recipient_registered = false //To Fix
        is_sender = true
        transaction_id = nil
        self.description = description
        self.currency = currency
        self.amount = amount
        status = .Draft
        reduced = false
        is_read = true
    }
}