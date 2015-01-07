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
    var counterpart_id: Int
    var recipient_registered: Bool
    var is_sender: Bool
    var transaction_id: Int
    var description: String
    var currency: String
    var amount: Double
    var kind: Int //not implemented, always 0
    var status: Int //0 = processed, 1 = waiting for validation by recipient, 3 = canceled or rejected
    var reduced: Bool
    var is_read: Bool
    var can_be_canceled: Bool
    var can_be_accepted: Bool

    init(transaction: NSDictionary) {
        if let time_sentString = transaction["time_sent"] as? String {
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
        

        if let time_updatedString = transaction["time_updated"] as? String {
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
        
        if let parsed = transaction["counterpart_name"] as? String {
            counterpart_name = parsed
        } else {
            counterpart_name = ""
            println("Failed to get counterpart_name parameter")
        }
        
        if let parsed = transaction["counterpart_id"] as? Int {
            counterpart_id = parsed
        } else {
            counterpart_id = 0
            println("Failed to get counterpart_id parameter")
        }
        
        if let parsed = transaction["recipient_registered"] as? Int {
            if (parsed == 1) {
                recipient_registered = true
            } else {
                recipient_registered = false
            }
        } else {
            recipient_registered = false
            println("Failed to get recipient_registered parameter")
        }
        
        if let parsed = transaction["is_sender"] as? Int {
            if (parsed == 1) {
                is_sender = true
            } else {
                is_sender = false
            }
        } else {
            is_sender = false
            println("Failed to get is_sender parameter")
        }
        
        if let parsed = transaction["transaction_id"] as? Int {
            transaction_id = parsed
        } else {
            transaction_id = 0
            println("Failed to get transaction_id parameter")
        }
        
        if let parsed = transaction["description"] as? String {
            description = parsed
        } else {
            description = ""
            println("Failed to get description parameter")
        }
        
        if let parsed = transaction["currency"] as? String {
            currency = parsed
        } else {
            currency = ""
            println("Failed to get currency parameter")
        }
        
        if let parsed = transaction["amount"] as? Double {
            amount = parsed
        } else {
            amount = 0
            println("Failed to get amount parameter")
        }
        
        if let parsed = transaction["kind"] as? Int {
            kind = parsed
        } else {
            kind = 0
            println("Failed to get kind parameter")
        }
        
        if let parsed = transaction["status"] as? Int {
            status = parsed
        } else {
            status = 0
            println("Failed to get status parameter")
        }
        
        if let parsed = transaction["reduced"] as? Int {
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
        
        can_be_canceled = false
        can_be_accepted = false
        
        
        //All variables have to be intialized before code as below can be writen
        let now = NSDate()
        let minfourDate = now.dateByAddingTimeInterval(NSTimeInterval(-60*4)) //in seconds
        if is_sender == true && (status == 0 || status == 1) && time_sent.compare(minfourDate) != NSComparisonResult.OrderedAscending { //only for last five minutes in API, so show four
            can_be_canceled = true
        } else {
            can_be_canceled = false
        }
        
        if status == 1 && self.is_sender == false {
            can_be_accepted = true
        } else {
            can_be_accepted = false
        }
    }
}