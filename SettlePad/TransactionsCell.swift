//
//  TransactionsCell.swift
//  SettlePad
//
//  Created by Rob Everhardt on 01/01/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class TransactionsCell: UITableViewCell {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var counterpartLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!

    @IBOutlet var spinner: UIActivityIndicatorView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func markup(transaction: Transaction){
        //Description
        descriptionLabel.text = transaction.description
        descriptionLabel.textColor = UIColor.blackColor()
		
        //Amount
        let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
        amountLabel.text = transaction.currency.rawValue+" \(transaction.amount.format(doubleFormat))"
        if (transaction.amount < 0) {
            let printamount = -1*transaction.amount
            amountLabel.textColor = Colors.gray.textToUIColor()
            amountLabel.text = "- " + transaction.currency.rawValue + " \(printamount.format(doubleFormat))"
        } else {
            amountLabel.textColor = Colors.success.textToUIColor()
            amountLabel.text = "+ " + transaction.currency.rawValue + " \(transaction.amount.format(doubleFormat))"
        }
        
        //Counterpart
		if let counterpart = transaction.counterpart {
			counterpartLabel.text = counterpart.name
		} else if let identifier = transaction.identifier {
			counterpartLabel.text = identifier
		} else {
			//When hit, transactions were loaded before contacts
			counterpartLabel.text =  "Unknown"
			contacts.updateContacts{(succeeded: Bool, error_msg: String?) -> () in }
		}
        counterpartLabel.textColor = UIColor.blackColor()

        
        //Time
        //See http://stackoverflow.com/questions/24577087/comparing-nsdates-without-time-component
        let today = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate()))
        let weekAgo = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate(timeIntervalSinceNow: -60*60*24*6)))
        
        var labeldateFormatter = NSDateFormatter()
        if (transaction.time_sent.compare(today!) != NSComparisonResult.OrderedAscending) {
            //Today, display time
            //http://makeapppie.com/tag/date-to-string-in-swift/
            labeldateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            labeldateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        } else if (transaction.time_sent.compare(weekAgo!) != NSComparisonResult.OrderedAscending) {
            //Last seven days, display day of the week
            labeldateFormatter.dateFormat = "eeee" //http://zframework.ph/swift-ios-date-formatting-options/
        } else {
            //Longer than 7 days ago, display date
            labeldateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
            labeldateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        }
        var dateString = labeldateFormatter.stringFromDate(transaction.time_sent)
        if (transaction.is_sender == false) {
            timeLabel.text = "Received: "+dateString
        } else {
            timeLabel.text = "Sent: "+dateString
        }
        timeLabel.textColor = Colors.gray.textToUIColor()

        
        //Status
        var statusString = "Unknown"
        if transaction.status == .Processed {
            statusLabel.hidden = false
            spinner.hidden = true
            amountLabel.hidden = false
            
            //processed
            if (transaction.reduced == false) {
                //not reduced (yet)
                statusString = ""
            } else {
                //reduced
                statusString = ""
            }

            statusLabel.text = statusString
            statusLabel.textColor = Colors.gray.textToUIColor()

        } else if transaction.status == .AwaitingValidation { // recipient should accept first
            statusLabel.hidden = false
            spinner.hidden = true
            amountLabel.hidden = false
            
            if (transaction.is_sender == true) { // 0 = recipient
                statusString = "Pending approval"
                statusLabel.textColor = Colors.gray.textToUIColor()
            } else {
                statusString = "Swipe to approve"
                statusLabel.textColor = Colors.primary.textToUIColor()
            }
            
            statusLabel.text = statusString
            
        } else if transaction.status == .Draft {
            statusLabel.hidden = false
            spinner.hidden = true
            amountLabel.hidden = false
            
            statusLabel.textColor = Colors.primary.textToUIColor()
            statusLabel.text = "Swipe to delete"
        } else if transaction.status == .Posted {
            statusLabel.hidden = true
            spinner.hidden = false
            amountLabel.hidden = true
            
            spinner.startAnimating()
            statusLabel.textColor = Colors.gray.textToUIColor()
        } else { // cancelled/ rejected
            statusLabel.hidden = false
            spinner.hidden = true
            amountLabel.hidden = false
            
            //transaction canceled
            statusString = "Rejected/ canceled"
            statusLabel.text = statusString
            
            //all labels in grey (Hex 777777)
            counterpartLabel.textColor = Colors.gray.textToUIColor()
            amountLabel.textColor = Colors.gray.textToUIColor()
            descriptionLabel.textColor = Colors.gray.textToUIColor()
            statusLabel.textColor = Colors.gray.textToUIColor()
            timeLabel.textColor = Colors.gray.textToUIColor()
            
            
            //all labels strikethrough
            var attributedcounterpartText = NSMutableAttributedString(string: counterpartLabel.text!)
            attributedcounterpartText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedcounterpartText.length))
            counterpartLabel.attributedText = attributedcounterpartText
            
            var attributedamountText = NSMutableAttributedString(string: amountLabel.text!)
            attributedamountText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedamountText.length))
            amountLabel.attributedText = attributedamountText
            
            var attributeddescriptionText = NSMutableAttributedString(string: descriptionLabel.text!)
            attributeddescriptionText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributeddescriptionText.length))
            descriptionLabel.attributedText = attributeddescriptionText
            
            /*
            var attributedstatusText = NSMutableAttributedString(string: statusLabel.text!)
            attributedstatusText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedstatusText.length))
            statusLabel.attributedText = attributedstatusText
            */
            
            var attributedtimeText = NSMutableAttributedString(string: timeLabel.text!)
            attributedtimeText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedtimeText.length))
            timeLabel.attributedText = attributedtimeText
        }
        
    }
    
}
