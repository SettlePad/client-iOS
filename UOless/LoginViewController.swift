//
//  LoginViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 03/11/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

import UIKit
var api = APIController()


class LoginViewController: UIViewController {
    /*See 
        http://www.raywenderlich.com/74904/swift-tutorial-part-2-simple-ios-app
        http://www.raywenderlich.com/83276/beginning-adaptive-layout-tutorial
    */
    
    @IBOutlet var txtLoginUser : UITextField! //You’re marking the variables with an exclamation mark (!). This indicates the variables are optional values, but they are implicitly unwrapped. This is a fancy way of saying you can write code assuming that they are set, and your app will crash if they are not set.
    @IBOutlet var txtLoginPass : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton) {
        api.login(txtLoginUser.text, password: txtLoginPass.text){ (succeeded: Bool, msg: String) -> () in
            if(succeeded) {
                //Go to next screen
                //let new_view:TransactionsViewController = TransactionsViewController()
                //self.presentViewController(new_view, animated: true, completion: nil)

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as UIViewController
                self.presentViewController(vc, animated: false, completion: nil)
                
            } else {
                var alert = UIAlertView(title: "Success!", message: msg, delegate: nil, cancelButtonTitle: "Okay.")
                alert.title = "Error"
                alert.message = msg
                
                // Move to the UI thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Show the alert
                    alert.show()
                })
            }
        }
    }
}

