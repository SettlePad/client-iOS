//
//  NewUOmeAddressBook.swift
//  UOless
//
//  Created by Rob Everhardt on 19/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

//See https://github.com/PaulSolt/Custom-UI-from-XIB-Xcode-6-IBDesignable/blob/master/Custom%20View%20from%20Xib/Custom%20View%20from%20Xib/Widget.swift

import UIKit

class NewUOmeAddressBook: UIView {
    typealias footerUpdatedDelegate = (NewUOmeAddressBook,CGFloat?) -> ()
    var footerUpdated: footerUpdatedDelegate?
    
    @IBOutlet var buttonToDetailConstraint: NSLayoutConstraint!
    @IBOutlet var requestAdressBookAccessButton: UIButton!
    
    @IBOutlet var detailLabel: UILabel!
    
    @IBAction func giveAccessButton(sender: AnyObject) {
        contacts.requestLocalAccess { (succeeded) -> () in
            self.updateFooter()
        }
    }
        
    required init(coder aDecoder: NSCoder) {
        //fatalError("This class does not support NSCoding")
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //setTranslatesAutoresizingMaskIntoConstraints(false)

        updateFooter()
    }
    
    func updateFooter() {
        //Determine address book status
        switch contacts.localStatus{
            case .Authorized:
                dispatch_async(dispatch_get_main_queue(), {
                    self.requestAdressBookAccessButton.hidden = true
                    self.buttonToDetailConstraint.active = false
                    self.detailLabel.hidden = true
                })
            case .Denied:
                dispatch_async(dispatch_get_main_queue(), {
                    self.requestAdressBookAccessButton.hidden = true
                    self.buttonToDetailConstraint.active = false
                    self.detailLabel.hidden = false
                    self.detailLabel.text = "You denied UOless access to your local address book, which is why we can only show contacts you've already exchanged UOmes with. You can allow access to your address book in the iOS settings (Privacy, Contacts)."
                })
            case .NotDetermined:
                dispatch_async(dispatch_get_main_queue(), {
                    self.requestAdressBookAccessButton.hidden = false
                    self.buttonToDetailConstraint.active = true
                    self.detailLabel.hidden = false
                    self.detailLabel.text = "UOless will not upload any personal data from your contacts to its servers. The technical details: a salted hash of the email addresses and phone numbers of your contacts will at some point in the future created and stored at the servers, to be able to tell you who of your contacts is using our service."
                })
            case .Restricted:
                dispatch_async(dispatch_get_main_queue(), {
                    self.requestAdressBookAccessButton.hidden = true
                    self.buttonToDetailConstraint.active = false
                    self.detailLabel.hidden = false
                    self.detailLabel.text = "UOless cannot access your contacts, possibly due to restrictions such as parental controls."
                })
        }

        if (contacts.localStatus == .Authorized) {
            footerUpdated?(self, 0) //no height for footer
        } else {
            footerUpdated?(self, nil)
        }
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */

}
