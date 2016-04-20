//
//  MessageViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 20/04/16.
//  Copyright © 2016 SettlePad. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {

    @IBOutlet var messageTextField: UITextField!
    
    @IBAction func sendPressed(sender: UIBarButtonItem) {
		if let message = messageTextField.text {
			activeUser?.sendMessage(message, success: {
				self.navigationController?.popViewControllerAnimated(true)
				}, failure: { (error) in
					displayError(error.errorText,viewController: self)
			})
		}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		messageTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
