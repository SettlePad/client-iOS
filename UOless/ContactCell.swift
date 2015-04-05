//
//  ContactCell.swift
//  UOless
//
//  Created by Rob Everhardt on 05/04/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet var starImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var limitCountLabel: UILabel!
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
        
        nameLabel.text = contact.friendlyName
        self.contact = contact
        limitCountLabel.text = "\(contact.limits.count)"
    }
    
    
}
