//
//  ErrorMessage.swift
//  UOless
//
//  Created by Rob Everhardt on 04/04/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

func displayError(errorMessage: String, viewController: UIViewController) {
    let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .Alert)
    let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alertController.addAction(OKAction)

    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        viewController.presentViewController(alertController, animated: true, completion: nil)
		if (user == nil && viewController.restorationIdentifier != "LoginController") {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") as! UIViewController
			viewController.presentViewController(vc, animated: false, completion: nil)
        }
    })
}