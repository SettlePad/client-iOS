//
//  IdentifierCell.swift
//  SettlePad
//
//  Created by Rob Everhardt on 09/07/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class IdentifierCell: UITableViewCell {
	//TODO: move into viewcontrollers
	
	@IBOutlet var identifierLabel: UILabel!
	@IBOutlet var verificationLabel: UILabel!
	@IBOutlet var processingSpinner: UIActivityIndicatorView!
	
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
		if identifier.pending {
			processingSpinner.hidden = false
			verificationLabel.hidden = true
			processingSpinner.startAnimating()
		} else {
			processingSpinner.hidden = true
			verificationLabel.hidden = false
			if identifier.verified {
				verificationLabel.text = "verified"
				verificationLabel.textColor = Colors.success.textToUIColor()
			} else {
				verificationLabel.text = "not verified"
				verificationLabel.textColor = Colors.danger.textToUIColor()
			}
		}
	}
	
}
