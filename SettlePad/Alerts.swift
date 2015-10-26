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
	let OKAction = UIAlertAction(title: "OK", style: .Default) { action -> Void in
		if (activeUser == nil && viewController.restorationIdentifier != "LoginController") {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") 
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				viewController.presentViewController(vc, animated: false, completion: nil)
			})
		}
	}
	
    alertController.addAction(OKAction)

    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        viewController.presentViewController(alertController, animated: true, completion: nil)

    })
}

func displayValidationFormNotLoggedIn(identifierStr: String, viewController: UIViewController, verificationCanceled: () -> (), verificationStarted: () -> (), verificationCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
	
	let alertController = UIAlertController(title: "Validate " + identifierStr, message: "Enter the token you received in your email", preferredStyle: .Alert)
	
	let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
		verificationCanceled()
	}
	
	let enterAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
		verificationStarted()
		let validationTextField = alertController.textFields![0] 
		Login.verifyIdentifier(identifierStr, token: validationTextField.text!,
			success: {
				verificationCompleted(succeeded: true, error_msg: nil)
			},
			failure: { error in
				verificationCompleted(succeeded: false, error_msg: error.errorText)
			}
		)
	}
	
	alertController.addTextFieldWithConfigurationHandler { (textField) in
		textField.placeholder = "Token"
	}
	
	alertController.addAction(cancelAction)
	alertController.addAction(enterAction)
	
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		viewController.presentViewController(alertController, animated: true, completion: nil)
	})
}

func displayValidationFormLoggedIn(identifier: UserIdentifier, viewController: UIViewController, requestCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
	
	let alertController = UIAlertController(title: "Validate " + identifier.identifier, message: "Enter the token you received in your email", preferredStyle: .Alert)
	
	let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
	}
	
	let enterAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
		let validationTextField = alertController.textFields![0]
		activeUser!.verifyIdentifier(identifier, token: validationTextField.text!) { (succeeded: Bool, error_msg: String?) -> () in
			if !succeeded {
				requestCompleted(succeeded: false, error_msg: error_msg!)
			} else {
				requestCompleted(succeeded: true, error_msg: nil)
			}
		}
	}
	
	alertController.addTextFieldWithConfigurationHandler { (textField) in
		textField.placeholder = "Token"
	}
	
	alertController.addAction(cancelAction)
	alertController.addAction(enterAction)
	
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		viewController.presentViewController(alertController, animated: true, completion: nil)
	})
}

func displayIncorrectPasswordForm(identifierStr: String, viewController: UIViewController, verificationCanceled: () -> (), verificationStarted: () -> (), verificationCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
	
	let alertController = UIAlertController(title: "Incorrect password", message: "Either the account does not exist, or you entered the wrong password. If you are sure the account exists and want to reset your password, a link to do so will be sent to your email address. With the token you receive, you can change your password", preferredStyle: .Alert)
	
	let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
		verificationCanceled()
	}
	
	let requestAction = UIAlertAction(title: "Request reset", style: .Destructive) { (action) in
		verificationStarted()
		Login.requestPasswordReset(identifierStr,
			success: {
				displayResetPasswordForm(identifierStr, viewController: viewController, verificationCanceled: {() -> () in
					//When canceled
					verificationCanceled()
					},verificationStarted: {() -> () in
						//verification started
						verificationStarted()
					}) { (succeeded, error_msg) -> () in
						verificationCompleted(succeeded: succeeded, error_msg: error_msg)
				}
			},
			failure: {error in
				verificationCompleted(succeeded: false, error_msg: error.errorText)
			}
		)
	}
	
	let resetAction = UIAlertAction(title: "Change with received token", style: .Default) { (action) in
		displayResetPasswordForm(identifierStr, viewController: viewController, verificationCanceled: {() -> () in
			//When canceled
			verificationCanceled()
		},verificationStarted: {() -> () in
			//verification started
			verificationStarted()
		}) { (succeeded, error_msg) -> () in
			verificationCompleted(succeeded: succeeded, error_msg: error_msg)
		}
	}
	
	
	alertController.addAction(cancelAction)
	alertController.addAction(requestAction)
	alertController.addAction(resetAction)
	
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		viewController.presentViewController(alertController, animated: true, completion: nil)
	})
}

func displayResetPasswordForm(identifierStr: String, viewController: UIViewController, verificationCanceled: () -> (), verificationStarted: () -> (), verificationCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
	let alertController = UIAlertController(title: "Change the password for " + identifierStr, message: "Enter a new password and the token you received in your email", preferredStyle: .Alert)
	
	let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
		verificationCanceled()
	}
	
	let enterAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
		verificationStarted()
		let passwordTextField = alertController.textFields![0] 
		let tokenTextField = alertController.textFields![1] 
		Login.resetPassword(identifierStr, passwordStr: passwordTextField.text!, tokenStr: tokenTextField.text!,
			success: {
				verificationCompleted(succeeded: true, error_msg: passwordTextField.text)
			},
			failure: {error in
				verificationCompleted(succeeded: false, error_msg: error.errorText)
			}
		)
	}
	
	alertController.addTextFieldWithConfigurationHandler { (textField) in
		textField.placeholder = "New password"
		textField.secureTextEntry = true
	}
	
	alertController.addTextFieldWithConfigurationHandler { (textField) in
		textField.placeholder = "Token"
	}
	

	alertController.addAction(cancelAction)
	alertController.addAction(enterAction)
	
	dispatch_async(dispatch_get_main_queue(), { () -> Void in
		viewController.presentViewController(alertController, animated: true, completion: nil)
	})
}
	