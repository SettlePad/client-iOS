//
//  footerView.swift
//  UOless
//
//  Created by Rob Everhardt on 03/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class footerView: UIView {
    var end_reached = true
    var no_results = true
    var searching = false
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.opaque = false //Required for transparent background
    }
    
    convenience override init () {
        self.init(frame:CGRectMake(0, 0, 320, 44)) //By default, make a rect of 320x44
    }
    
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
            footerLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0) //#777777
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
