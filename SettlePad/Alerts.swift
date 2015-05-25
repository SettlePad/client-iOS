//
//  ErrorMessage.swift
//  SettlePad
//
//  Created by Rob Everhardt on 04/04/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
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

func displayValidationForm(identifierStr: String, viewController: UIViewController, verificationCanceled: () -> (), verificationStarted: () -> (), verificationCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
	
	let alertController = UIAlertController(title: "Validate " + identifierStr, message: "Enter the validationcode you received in your email", preferredStyle: .Alert)
	
	let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
		verificationCanceled()
	}
	
	let enterAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
		verificationStarted()
		let validationTextField = alertController.textFields![0] as! UITextField
		api.verifyIdentifier(identifierStr, token: validationTextField.text) { (succeeded: Bool, error_msg: String?) -> () in
			if !succeeded {
				verificationCompleted(succeeded: false, error_msg: error_msg!)
			} else {
				verificationCompleted(succeeded: true, error_msg: nil)
			}
		}
	}
	
	alertController.addTextFieldWithConfigurationHandler { (textField) in
		textField.placeholder = "Validation code"
	}
	
	
	alertController.addAction(cancelAction)
	alertController.addAction(enterAction)
	
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		viewController.presentViewController(alertController, animated: true, completion: nil)
	})
}