//
//  ContactCell.swift
//  SettlePad
//
//  Created by Rob Everhardt on 05/04/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
	
	@IBOutlet var starImageView: UIImageView!
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var limitIndicator: UILabel!
	
	var contact: Contact?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func markup(contact: Contact){
		if contact.favorite {
			starImageView.image = UIImage(named: "StarFull")
		} else {
			starImageView.image = UIImage(named: "StarEmpty")
		}
		
		nameLabel.text = contact.resultingName
		self.contact = contact
		if contact.limits.count == 0 {
			limitIndicator.text = ""
		} else if contact.limits.count == 1 {
			//let limit = contact.limits[0] as Limit
			//let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
			//limitIndicator.text = limit.currency.rawValue + " " + limit.limit.format(doubleFormat)
			limitIndicator.text = "Limit set"
		} else {
			limitIndicator.text = "Limits set"
		}
	}
	
	
}
