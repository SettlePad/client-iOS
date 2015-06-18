//
//  LoginViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 03/11/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
var settingsDictionary = NSDictionary(contentsOfFile: documentList!)

var api = APIController()
var user = User() //If nil, not logged in
var transactions=Transactions()
var contacts = Contacts()
var balances = Balances()


class LoginViewController: UIViewController {
	/*See 
        http://www.raywenderlich.com/74904/swift-tutorial-part-2-simple-ios-app
        http://www.raywenderlich.com/83276/beginning-adaptive-layout-tutorial
    */
	
	//TODO: disable zombies
    
    @IBOutlet var txtLoginName: UITextField!
    @IBOutlet var txtLoginUser : UITextField! //You’re marking the variables with an exclamation mark (!). This indicates the variables are optional values, but they are implicitly unwrapped. This is a fancy way of saying you can write code assuming that they are set, and your app will crash if they are not set.
    @IBOutlet var txtLoginPass : UITextField!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var loginButton: UIButton!

    @IBOutlet var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton) {
        doLogin()
    }
	
	var formForRegistration = false
    
    func doLogin() {
		if formForRegistration == false {
			spinning(true)
			
			api.login(txtLoginUser.text, password: txtLoginPass.text){ (succeeded: Bool, msg: String, code: String) -> () in
				self.spinning(false)
				if(succeeded) {
					//Go to next screen (in main view)
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						self.txtLoginPass.text = ""
					})
					self.enter_app()
				} else {
					if (code == "not_validated" ) {
						//Show validation form
						displayValidationForm(self.txtLoginUser.text, self, {() -> () in self.spinning(false)},{}) { (succeeded, error_msg) -> () in
							
							self.spinning(false)
							
							if !succeeded {
								displayError(error_msg!,self)
							} else {
								//When validated: log in
								self.doLogin()
							}
						}
					} else if (code == "incorrect_credentials" ) {
						//Offer to reset password
						displayIncorrectPasswordForm(self.txtLoginUser.text, self, {() -> () in
							//When canceled
							self.spinning(false)
							dispatch_async(dispatch_get_main_queue(), { () -> Void in
								self.txtLoginPass.text = ""
							})
						},{}) { (succeeded, error_msg) -> () in
							//When indeed requested password reset
							if !succeeded {
								displayError(error_msg!,self)
							} else {
								//When validated: log in
								self.txtLoginPass.text = error_msg!
								self.doLogin()
							}
						}
					} else {
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							self.txtLoginPass.text = ""
						})
						displayError(msg, self)
					}
				}
			}
		} else {
			//check whether email address is valid
			var preferredCurency: String = "EUR"
			if let currencyCode = NSLocale.currentLocale().objectForKey(NSLocaleCurrencyCode) as? String {
				preferredCurency = currencyCode
			}
			
			if validateRegistrationForm(false, finalCheck: true) {
				spinning(true)
				
				api.register(txtLoginName.text, username: txtLoginUser.text, password: txtLoginPass.text, preferredCurrency: preferredCurency){ (succeeded: Bool, error_msg: String?, userID: Int?) -> () in
					
					if(succeeded) {
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							self.register(self) //switch back to login view
						})
							
						//Show validation form
						displayValidationForm(self.txtLoginUser.text, self, {() -> () in self.spinning(false)},{}) { (succeeded, error_msg) -> () in
							
							self.spinning(false)
							
							if !succeeded {
								displayError(error_msg!,self)
							} else {
								//When validated: log in
								self.doLogin()
							}
						}

					} else {
						self.spinning(false)
						displayError(error_msg!, self)
					}
				}
			}
        }
    }
	
    @IBAction func register(sender: AnyObject) {
		if formForRegistration == false {
			formForRegistration = true
			txtLoginName.hidden = false
			loginButton.setTitle("Register", forState: UIControlState.Normal)
			registerButton.setTitle("Cancel", forState: UIControlState.Normal)
			txtLoginName.becomeFirstResponder()
		} else {
			formForRegistration = false
			txtLoginName.hidden = true
			loginButton.setTitle("Login", forState: UIControlState.Normal)
			registerButton.setTitle("Register", forState: UIControlState.Normal)
			txtLoginUser.becomeFirstResponder()
		}
    }
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if user != nil {
			spinning(true)
			contacts.updateContacts{(succeeded: Bool, error_msg: String?) -> () in
				self.spinning(false)
				self.enter_app() //load contacts before entering
				contacts.updateAutoLimits(){}
			}

			//Update user name, default currency and identifiers
			user!.updateSettings() { (succeeded: Bool, error_msg: String?) -> () in
				if !succeeded {
					println(error_msg!)
				}
			}
        }
    }
    
	
    
    @IBAction func viewTapped(sender : AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        //textfields that should trigger this need to have their delegate set to the viewcontroller
        
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
        dispatch_async(dispatch_get_main_queue()) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("TabBarController") as! UIViewController
            self.presentViewController(vc, animated: false, completion: nil)
        }
		
		// Register for Push Notitications, if running iOS 8
		//if UIApplication.sharedApplication().respondsToSelector("registerUserNotificationSettings:") {
		let types:UIUserNotificationType = (.Alert | .Badge | .Sound)
		let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
		
		UIApplication.sharedApplication().registerUserNotificationSettings(settings)
		UIApplication.sharedApplication().registerForRemoteNotifications()
		UIApplication.sharedApplication().applicationIconBadgeNumber = 0
		
		/*} else {
		// Register for Push Notifications before iOS 8
		UIApplication.sharedApplication().registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
		}*/
		
    }
	
	func spinning(spin: Bool) {
		if spin {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.spinner.hidden = false
				self.loginButton.hidden = true
				self.loginButton.enabled = false
				self.registerButton.hidden = true
				self.registerButton.enabled = false
			})
		} else {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.spinner.hidden = true
				self.loginButton.hidden = false
				self.loginButton.enabled = true
				self.registerButton.hidden = false
				self.registerButton.enabled = true
			})
		}
	}
	
	func validateRegistrationForm (whileEditing: Bool, finalCheck: Bool) -> Bool {
		var isValid = true
		var hasGivenFirstResponder = false
		
		/*Could also color the border, with
		formTo.layer.borderWidth = 1.0
		formTo.layer.borderColor = Colors.danger.textToUIColor().CGColor
		*/
		
		
		if txtLoginName.text != "" {
			txtLoginName.backgroundColor = nil
			txtLoginName.textColor = nil
		} else {
			isValid = false
			if finalCheck {
				txtLoginName.backgroundColor = Colors.danger.backgroundToUIColor()
				txtLoginName.textColor = Colors.danger.textToUIColor()
				if (!hasGivenFirstResponder && finalCheck) {
					txtLoginName.becomeFirstResponder()
					hasGivenFirstResponder = true
				}
				
			}
		}
		
		if txtLoginUser.text.isEmail() {
			txtLoginUser.backgroundColor = nil
			txtLoginUser.textColor = nil
		} else {
			isValid = false
			if finalCheck || (txtLoginUser.text != "" && !whileEditing) {
				txtLoginUser.backgroundColor = Colors.danger.backgroundToUIColor()
				txtLoginUser.textColor = Colors.danger.textToUIColor()
				if (!hasGivenFirstResponder && finalCheck) {
					txtLoginUser.becomeFirstResponder()
					hasGivenFirstResponder = true
				}
			}
		}

		if txtLoginPass.text != "" {
			txtLoginPass.backgroundColor = nil
			txtLoginPass.textColor = nil
		} else {
			isValid = false
			if finalCheck {
				txtLoginPass.backgroundColor = Colors.danger.backgroundToUIColor()
				txtLoginPass.textColor = Colors.danger.textToUIColor()
				if (!hasGivenFirstResponder && finalCheck) {
					txtLoginPass.becomeFirstResponder()
					hasGivenFirstResponder = true
				}
				
			}
		}
		
		return isValid
	}
    @IBAction func loginUserEditingDidChange(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(true,finalCheck: false)
		}
	}
    @IBAction func loginUserEditingDidEnd(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(false,finalCheck: false)
		}
    }
    @IBAction func loginPassEditingDidChange(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(true,finalCheck: false)
		}
    }
    @IBAction func loginPassEditingDidEnd(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(false,finalCheck: false)
		}
    }
    @IBAction func loginNameEditingDidChange(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(true,finalCheck: false)
		}
    }
    @IBAction func loginNameEditingDidEnd(sender: AnyObject) {
		if formForRegistration {
			validateRegistrationForm(false,finalCheck: false)
		}
    }
}