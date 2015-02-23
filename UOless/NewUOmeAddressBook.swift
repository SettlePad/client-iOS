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

    @IBAction func giveAccessButton(sender: AnyObject) {
        
    }
    
    override init(frame: CGRect) {
        // properties
        super.init(frame: frame)
        
        // Setup
        let view = UINib(nibName: "NewUOmeAdressBook", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as UIView
        self.opaque = false
        
        view.frame = self.bounds
        

        //view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        addSubview(view)
    }
    
    required init(coder aDecoder: NSCoder) {
        //fatalError("This class does not support NSCoding")
        super.init(coder: aDecoder)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
