//
//  IdentifiersViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 24/03/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

// See http://nshipster.com/uialertcontroller/

import UIKit

class IdentifiersViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //Hide additional gridlines, and set gray background for footer
        self.tableView.tableFooterView = UIView(frame:CGRectZero)
        //self.tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
		if activeUser != nil {
			return activeUser!.userIdentifiers.count
		} else {
			return 0
		}
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("emailAddressRow", forIndexPath: indexPath) as! IdentifierCell

        // Configure the cell...
		
		
        let identifier = activeUser!.userIdentifiers[indexPath.row]
		cell.markup(identifier)
        
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
		return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        /*if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } */
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?  {
        let identifier = activeUser!.userIdentifiers[indexPath.row]
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete" , handler: { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.deleteIdentifier(identifier, tableView: tableView, indexPath: indexPath)
        })
        
        deleteAction.backgroundColor = Colors.danger.textToUIColor()
        return [deleteAction]
    }
    
    func deleteIdentifier (identifier: UserIdentifier, tableView: UITableView, indexPath: NSIndexPath) {
		var message: String
		if activeUser!.userIdentifiers.count == 1 {
			message = "If you proceed, you will close your account and log out. You cannot login ever again. Are you sure that is what you want?"
		} else {
			message = "Do you really want to delete "+identifier.identifier+"?"
		}
		
        let alertController = UIAlertController(title: "Are you sure?", message: message, preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            tableView.setEditing(false, animated: true)
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            tableView.setEditing(false, animated: true)
            activeUser!.deleteIdentifier(identifier,
				success: {
					if activeUser != nil {
						if activeUser!.userIdentifiers.count == 0 {
							clearUser() //No need to logout on the server, that is already done with removing the last identifier
							dispatch_async(dispatch_get_main_queue()) {
								let storyboard = UIStoryboard(name: "Main", bundle: nil)
								let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController")
								self.presentViewController(vc, animated: false, completion: nil)
							}
						} else {
							dispatch_async(dispatch_get_main_queue(), {
								self.tableView.reloadData()
							})
						}
					}		
				},
				failure: {error in
                    displayError(error.errorText,viewController: self)
				}
			)
			
			//already add with spinner
			dispatch_async(dispatch_get_main_queue(), {
				self.tableView.reloadData()
			})
        }
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
	
	func setPrimary(identifier: UserIdentifier) {
		dispatch_async(dispatch_get_main_queue(), {
			self.tableView.reloadData()
		})
		activeUser!.setAsPrimary(identifier, success: {},
			failure: {error in
				displayError(error.errorText,viewController: self)
				
				dispatch_async(dispatch_get_main_queue(), {
					self.tableView.reloadData()
				})
			}
		)
	}
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let identifier = activeUser!.userIdentifiers[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath)

		//show Action sheet

		let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
		
		//For iPad
		actionSheetController.popoverPresentationController?.sourceView = tableView.cellForRowAtIndexPath(indexPath)
		actionSheetController.popoverPresentationController?.sourceRect = tableView.cellForRowAtIndexPath(indexPath)!.bounds
		
		let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
			//Just dismiss the action sheet
		}
		actionSheetController.addAction(cancelAction)
		
		let changePasswordAction: UIAlertAction = UIAlertAction(title: "Change password", style: .Default) { action -> Void in
			self.changePasswordForm(identifier)
		}
		actionSheetController.addAction(changePasswordAction)
		
		if identifier.verified == false {
			let verifyAction: UIAlertAction = UIAlertAction(title: "Enter verification code", style: .Default) { action -> Void in
				let identifier = activeUser!.userIdentifiers[indexPath.row]
				self.validationCodeForm(identifier)
			}
			actionSheetController.addAction(verifyAction)
			
			let resendCodeAction: UIAlertAction = UIAlertAction(title: "Resend verification code", style: .Default) { action -> Void in
				activeUser!.resendToken(identifier,
					failure: {error in
						displayError(error.errorText,viewController: self)
					}
				)
			}
			actionSheetController.addAction(resendCodeAction)
		}
	
		if identifier.primary == false && identifier.verified {
			let setPrimaryAction: UIAlertAction = UIAlertAction(title: "Set as primary", style: .Default) { action -> Void in
				let identifier = activeUser!.userIdentifiers[indexPath.row]
				self.setPrimary(identifier)
			}
			actionSheetController.addAction(setPrimaryAction)
		}
		
		let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
			let identifier = activeUser!.userIdentifiers[indexPath.row]
			self.deleteIdentifier (identifier, tableView: tableView, indexPath: indexPath)
		}
		actionSheetController.addAction(deleteAction)

		//We need to provide a popover sourceView when using it on iPad
		actionSheetController.popoverPresentationController?.sourceView = cell?.contentView
		actionSheetController.popoverPresentationController?.permittedArrowDirections = [UIPopoverArrowDirection.Up, UIPopoverArrowDirection.Down]
		actionSheetController.popoverPresentationController?.sourceRect = CGRectMake(cell!.frame.width / 2, cell!.frame.height,0,0)

		//Present the AlertController
		self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func changePasswordForm(identifier: UserIdentifier) {
        //show change password form
        let alertController = UIAlertController(title: "Change password", message: "Enter your new password twice to change it", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        
        let changeAction = UIAlertAction(title: "Change", style: .Default) { (action) in
            let firstPasswordTextField = alertController.textFields![0] 
            activeUser!.changePassword(identifier, password: firstPasswordTextField.text!,
				failure: {error in
                    displayError(error.errorText,viewController: self)
                }
            )
        }
        changeAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.addTarget(self, action: #selector(IdentifiersViewController.changePasswordFormTextChanged(_:)), forControlEvents: .EditingChanged)
        }
        
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password (again)"
            textField.secureTextEntry = true
            textField.addTarget(self, action: #selector(IdentifiersViewController.changePasswordFormTextChanged(_:)), forControlEvents: .EditingChanged)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(changeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func changePasswordFormTextChanged(sender:AnyObject) {
        //get a handler to the UIAlertController
        let tf = sender as! UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alertController = resp as! UIAlertController
        
        let firstPasswordTextField = alertController.textFields![0] 
        let secondPasswordTextField = alertController.textFields![1] 
        
        (alertController.actions[1] ).enabled = (
                firstPasswordTextField.text != "" &&
                firstPasswordTextField.text == secondPasswordTextField.text
        )
    }
    

    @IBAction func newIdentifierAction(sender: AnyObject) {
        //show new identifier form
        let alertController = UIAlertController(title: "New identifier", message: nil, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in

        }
        
        let addAction = UIAlertAction(title: "Add", style: .Default) { (action) in
            let emailTextField = alertController.textFields![0] 
            let firstPasswordTextField = alertController.textFields![1] 
			
            activeUser!.addIdentifier(emailTextField.text!, password: firstPasswordTextField.text!,
				success: {
					dispatch_async(dispatch_get_main_queue(), {
						self.tableView.reloadData()
					})
				},
				failure: {error in
					displayError(error.errorText,viewController: self)
				}
			)
			dispatch_async(dispatch_get_main_queue(), {
				self.tableView.reloadData()
			})

        }
        addAction.enabled = false

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Email address"
            textField.secureTextEntry = false
            textField.addTarget(self, action: #selector(IdentifiersViewController.newIdentifierFormTextChanged(_:)), forControlEvents: .EditingChanged)
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.addTarget(self, action: #selector(IdentifiersViewController.newIdentifierFormTextChanged(_:)), forControlEvents: .EditingChanged)
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password (again)"
            textField.secureTextEntry = true
            
            textField.addTarget(self, action: #selector(IdentifiersViewController.newIdentifierFormTextChanged(_:)), forControlEvents: .EditingChanged)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func newIdentifierFormTextChanged(sender:AnyObject) {
        //get a handler to the UIAlertController
        let tf = sender as! UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alertController = resp as! UIAlertController
        
        let emailTextField = alertController.textFields![0] 
        let firstPasswordTextField = alertController.textFields![1] 
        let secondPasswordTextField = alertController.textFields![2] 
        
        alertController.actions[1].enabled = (
            emailTextField.text!.isEmail() &&
            firstPasswordTextField.text != "" &&
            firstPasswordTextField.text == secondPasswordTextField.text
        )
    }
    
    func validationCodeForm(identifier: UserIdentifier) {
        //show validation code form
		displayValidationFormLoggedIn(identifier, viewController: self,
			requestCompleted: {(succeeded, error_msg) -> () in
				if !succeeded {
					displayError(error_msg!,viewController: self)
				}
				dispatch_async(dispatch_get_main_queue(), {
					self.tableView.reloadData() //To show result
				})
			}
		)
		dispatch_async(dispatch_get_main_queue(), {
			self.tableView.reloadData() //To show spinner
		})
	}
}

class IdentifierCell: UITableViewCell {
	@IBOutlet var identifierLabel: UILabel!
	@IBOutlet var verificationLabel: UILabel!
	@IBOutlet var processingSpinner: UIActivityIndicatorView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func markup(identifier: UserIdentifier){
		identifierLabel.text = identifier.identifier
		if identifier.pending {
			processingSpinner.hidden = false
			verificationLabel.hidden = true
			processingSpinner.startAnimating()
		} else {
			processingSpinner.hidden = true
			verificationLabel.hidden = false
			if identifier.verified {
				verificationLabel.text = ""
				//verificationLabel.textColor = Colors.success.textToUIColor()
			} else {
				verificationLabel.text = "not verified"
				verificationLabel.textColor = Colors.danger.textToUIColor()
			}
		}
		if identifier.primary {
			self.accessoryType = .Checkmark
		} else {
			self.accessoryType = .None
		}
	}
	
}
