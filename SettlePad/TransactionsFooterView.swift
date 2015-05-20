//
//  footerView.swift
//  SettlePad
//
//  Created by Rob Everhardt on 03/01/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

//TODO: move all these view classes into the viewcontrollers

class TransactionsFooterView: UIView {
    var end_reached = true
    var no_results = true
    var searching = false
    
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
        

        if self.end_reached || self.searching {
            let footerLabel: UILabel = UILabel(frame: rect)
            footerLabel.textColor = Colors.gray.textToUIColor()
            footerLabel.font = UIFont.boldSystemFontOfSize(11)
            footerLabel.textAlignment = NSTextAlignment.Center

            if self.searching {
                footerLabel.text = "Press search after entering your query"
            } else if self.no_results {
                footerLabel.text = "No transactions"
            } else {
                footerLabel.text = "No more transactions"
            }
            self.addSubview(footerLabel)
        } else {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            spinner.startAnimating()
            spinner.frame = rect
            self.addSubview(spinner)
        }
    }
}
