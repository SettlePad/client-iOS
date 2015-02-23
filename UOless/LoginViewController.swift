//
//  LoginViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 03/11/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

import UIKit

var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
var settingsDictionary = NSDictionary(contentsOfFile: documentList!)

var api = APIController()
var user: User? //If nil, not logged in
var transactions=Transactions()
var contacts = Contacts()

class LoginViewController: UIViewController {
    /*See 
        http://www.raywenderlich.com/74904/swift-tutorial-part-2-simple-ios-app
        http://www.raywenderlich.com/83276/beginning-adaptive-layout-tutorial
    */
    
    @IBOutlet var txtLoginUser : UITextField! //You’re marking the variables with an exclamation mark (!). This indicates the variables are optional values, but they are implicitly unwrapped. This is a fancy way of saying you can write code assuming that they are set, and your app will crash if they are not set.
    @IBOutlet var txtLoginPass : UITextField!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var loginBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        if user != nil {
            enter_app()
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrameNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton) {
        doLogin()
    }
    
    func doLogin() {
        spinner.hidden = false
        loginButton.hidden = true
        api.login(txtLoginUser.text, password: txtLoginPass.text){ (succeeded: Bool, msg: String) -> () in
            self.spinner.hidden = true
            self.loginButton.hidden = false
            if(succeeded) {
                //Go to next screen (in main view)
                self.enter_app()
            } else {
                var alert = UIAlertView(title: "Fail!", message: msg, delegate: nil, cancelButtonTitle: "Okay.")
                
                // Move to the UI thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Show the alert
                    alert.show()
                })
            }
        }
    }
    
    func keyboardWillChangeFrameNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve << 16))
        
        if (CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) > 0) {
            //will show
            self.loginBottomConstraint.constant = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame)
            self.loginBottomConstraint.priority = 750 //So that this one will overrule the other botom constraint
        } else {
            //will hide
            self.loginBottomConstraint.priority = 250 //So that the other bottom constraint (with fixed height) will take over
        }

        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: .BeginFromCurrentState | animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil
        )
    
        /*UIView.animateWithDuration(1, animations: { () -> Void in
            self.loginBottomConstraint.constant = keyboardFrame.size.height + 20
        })*/
    }
    
    
    @IBAction func viewTapped(sender : AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        //textField.resignFirstResponder()
        //self.view.endEditing(true);
        if (textField!.restorationIdentifier == "email") {
            //email, goto password
            txtLoginPass.becomeFirstResponder()
        } else {
            //password, login
            doLogin()
        }
        //println("return pressed")
        return true;
    }
    
    func enter_app() {
        //TODO: sometimes gives notice: Unbalanced calls to begin/end appearance transitions for <UOless.LoginViewController: 0x7ffd9971c8d0>.
        dispatch_async(dispatch_get_main_queue()) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as UIViewController
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
}