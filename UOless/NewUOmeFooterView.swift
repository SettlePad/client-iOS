//
//  NewUOmeFooterView.swift
//  UOless
//
//  Created by Rob Everhardt on 01/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class NewUOmeFooterView: UIView {
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.opaque = false //Required for transparent background
    }
    
    /*convenience override init () {
        self.init(frame:CGRectMake(0, 0, 320, 44)) //By default, make a rect of 320x44
    }*/
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    
    override func drawRect(rect: CGRect) {
        //To make sure we are not adding one layer of text onto another
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        
        let footerLabel: UILabel = UILabel(frame: rect)
        footerLabel.textColor = Colors.gray.textToUIColor()
        footerLabel.font = UIFont.boldSystemFontOfSize(11)
        footerLabel.textAlignment = NSTextAlignment.Center
        
        footerLabel.text = "Saved UOmes will be listed here to be all sent at once."
        self.addSubview(footerLabel)
    }

}
