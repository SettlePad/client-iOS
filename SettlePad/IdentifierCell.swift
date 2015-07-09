//
//  IdentifierCell.swift
//  SettlePad
//
//  Created by Rob Everhardt on 09/07/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class IdentifierCell: UITableViewCell {

	@IBOutlet var identifierLabel: UILabel!
	@IBOutlet var verificationLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	func markup(identifier: UserIdentifier){
		identifierLabel.text = identifier.identifier
		
		if identifier.verified {
			verificationLabel.text = "verified"
			verificationLabel.textColor = Colors.success.textToUIColor()
		} else {
			verificationLabel.text = "not verified"
			verificationLabel.textColor = Colors.danger.textToUIColor()
		}

	}
	
}
