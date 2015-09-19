//
//  NewUOmeAddressBook.swift
//  SettlePad
//
//  Created by Rob Everhardt on 19/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

//See https://github.com/PaulSolt/Custom-UI-from-XIB-Xcode-6-IBDesignable/blob/master/Custom%20View%20from%20Xib/Custom%20View%20from%20Xib/Widget.swift

import UIKit

class NewUOmeAddressBook: UIView {
	
    typealias footerUpdatedDelegate = (NewUOmeAddressBook) -> ()
    var footerUpdated: footerUpdatedDelegate?
    
    @IBOutlet var requestAddressBookAccessButton: UIButton!
    
    @IBOutlet var detailLabel: UILabel!
    
    @IBAction func giveAccessButton(sender: AnyObject) {
        contacts.requestLocalAccess(){ succeeded in
            self.footerUpdated?(self)
            return //to overcome implicit return, see http://expertland.net/question/p8n2l8193m8218a9c2t50fl71940ebbxz1/detail.html
        }
    }
    
 
    
    required init?(coder aDecoder: NSCoder) {
        //fatalError("This class does not support NSCoding")
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        //Determine address book status
        switch contacts.localStatus{
            case .Authorized:
                self.requestAddressBookAccessButton.removeFromSuperview()
                self.detailLabel.removeFromSuperview()
            case .Denied:
                self.requestAddressBookAccessButton.removeFromSuperview()
                self.detailLabel.text = "You denied access to your local address book, which is why we can only show contacts you've already exchanged UOmes with. You can allow access to your address book in the iOS settings (Privacy, Contacts)."
            case .NotDetermined:
                self.detailLabel.text = "We will not upload any personal data from your contacts to its servers. The technical details: a salted hash of the email addresses and phone numbers of your contacts will at some point in the future created and stored at the servers, to be able to tell you who of your contacts is using our service."
            case .Restricted:
                self.requestAddressBookAccessButton.removeFromSuperview()
                self.detailLabel.text = "We cannot access your contacts, possibly due to restrictions such as parental controls."
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
