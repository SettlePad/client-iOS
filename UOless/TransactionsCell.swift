//
//  TransactionsCell.swift
//  UOless
//
//  Created by Rob Everhardt on 01/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class TransactionsCell: UITableViewCell {

    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var counterpartLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var statusImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
