//
//  IdentifiersViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 24/03/15.
//  Copyright (c) 2015 UOless. All rights reserved.
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
        return user!.userIdentifiers.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("emailAddressRow", forIndexPath: indexPath) as UITableViewCell

        // Configure the cell...
        let identifier = user!.userIdentifiers[indexPath.row]
        cell.textLabel?.text  = identifier.identifier
        
        if identifier.verified {
            cell.detailTextLabel?.text = "verified"
            cell.detailTextLabel?.textColor = Colors.success.textToUIColor()
        } else {
            cell.detailTextLabel?.text = "not verified"
            cell.detailTextLabel?.textColor = Colors.danger.textToUIColor()
        }
        
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        if user!.userIdentifiers.count > 1 {
            return true
        } else {
            return false
        }
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        let identifier = user!.userIdentifiers[indexPath.row]
        
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            self.deleteIdentifier(identifier, tableView: tableView, indexPath: indexPath)
        })
        
        deleteAction.backgroundColor = Colors.danger.textToUIColor()
        return [deleteAction]
    }
    
    func deleteIdentifier (identifier: UserIdentifier, tableView: UITableView, indexPath: NSIndexPath) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Do you really want to delete "+identifier.identifier+"?", preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            tableView.setEditing(false, animated: true)
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete", style: .Destructive) { (action) in
            tableView.setEditing(false, animated: true)
            user!.deleteIdentifier(identifier) { (succeeded: Bool, error_msg: String?) -> () in
                if !succeeded {
                    displayError(error_msg!,self)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
        }
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
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
        let identifier = user!.userIdentifiers[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if (identifier.verified && user!.userIdentifiers.count == 1) {
            //only one option: change password
            changePasswordForm(identifier)
        } else {
            //show Action sheet

            let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
            
            let changePasswordAction: UIAlertAction = UIAlertAction(title: "Change password", style: .Default) { action -> Void in
                self.changePasswordForm(identifier)
            }
            actionSheetController.addAction(changePasswordAction)
            
            if (identifier.verified == false) {
                let verifyAction: UIAlertAction = UIAlertAction(title: "Enter verification code", style: .Default) { action -> Void in
                    let identifier = user!.userIdentifiers[indexPath.row]
                    self.validationCodeForm(identifier)
                }
                actionSheetController.addAction(verifyAction)
                
                let resendCodeAction: UIAlertAction = UIAlertAction(title: "Resend verification code", style: .Default) { action -> Void in
                    user!.resendToken(identifier) { (succeeded: Bool, error_msg: String?) -> () in
                        if !succeeded {
                            displayError(error_msg!,self)
                        }
                    }
                }
                actionSheetController.addAction(resendCodeAction)
            }
            
            if (user!.userIdentifiers.count > 1) {
                let verifyAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
                    let identifier = user!.userIdentifiers[indexPath.row]
                    self.deleteIdentifier (identifier, tableView: tableView, indexPath: indexPath)
                }
                actionSheetController.addAction(verifyAction)
            }

            //We need to provide a popover sourceView when using it on iPad
            actionSheetController.popoverPresentationController?.sourceView = cell?.contentView
            actionSheetController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up | UIPopoverArrowDirection.Down
            actionSheetController.popoverPresentationController?.sourceRect = CGRectMake(cell!.frame.width / 2, cell!.frame.height,0,0)

            //Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)
        }
    }
    
    func changePasswordForm(identifier: UserIdentifier) {
        //show change password form
        let alertController = UIAlertController(title: "Change password", message: "Enter your new password twice to change it", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        
        let changeAction = UIAlertAction(title: "Change", style: .Default) { (action) in
            let firstPasswordTextField = alertController.textFields![0] as UITextField
            user!.changePassword(identifier, password: firstPasswordTextField.text) { (succeeded: Bool, error_msg: String?) -> () in
                if !succeeded {
                    displayError(error_msg!,self)
                }
            }
        }
        changeAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.addTarget(self, action: "changePasswordFormTextChanged:", forControlEvents: .EditingChanged)
        }
        
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password (again)"
            textField.secureTextEntry = true
            textField.addTarget(self, action: "changePasswordFormTextChanged:", forControlEvents: .EditingChanged)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(changeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func changePasswordFormTextChanged(sender:AnyObject) {
        //get a handler to the UIAlertController
        let tf = sender as UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alertController = resp as UIAlertController
        
        let firstPasswordTextField = alertController.textFields![0] as UITextField
        let secondPasswordTextField = alertController.textFields![1] as UITextField
        
        (alertController.actions[1] as UIAlertAction).enabled = (
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
            let emailTextField = alertController.textFields![0] as UITextField
            let firstPasswordTextField = alertController.textFields![1] as UITextField
            
            user!.addIdentifier(emailTextField.text, password: firstPasswordTextField.text) { (succeeded: Bool, error_msg: String?) -> () in
                if !succeeded {
                    displayError(error_msg!,self)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
        }
        addAction.enabled = false

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Email address"
            textField.secureTextEntry = false
            textField.addTarget(self, action: "newIdentifierFormTextChanged:", forControlEvents: .EditingChanged)
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.addTarget(self, action: "newIdentifierFormTextChanged:", forControlEvents: .EditingChanged)
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password (again)"
            textField.secureTextEntry = true
            
            textField.addTarget(self, action: "newIdentifierFormTextChanged:", forControlEvents: .EditingChanged)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func newIdentifierFormTextChanged(sender:AnyObject) {
        //get a handler to the UIAlertController
        let tf = sender as UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alertController = resp as UIAlertController
        
        let emailTextField = alertController.textFields![0] as UITextField
        let firstPasswordTextField = alertController.textFields![1] as UITextField
        let secondPasswordTextField = alertController.textFields![2] as UITextField
        
        (alertController.actions[1] as UIAlertAction).enabled = (
            emailTextField.text.isEmail() &&
            firstPasswordTextField.text != "" &&
            firstPasswordTextField.text == secondPasswordTextField.text
        )
    }
    
    func validationCodeForm(identifier: UserIdentifier) {
        //show change password form
        let alertController = UIAlertController(title: "Validate " + identifier.identifier, message: "Enter the validationcode you received", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        
        let enterAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
            let validationTextField = alertController.textFields![0] as UITextField
            user!.verifyIdentifier(identifier, token: validationTextField.text) { (succeeded, error_msg) -> () in
                if !succeeded {
                    displayError(error_msg!,self)
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableView.reloadData()
                    })
                }
            }
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Validation code"
        }
        
        
        alertController.addAction(cancelAction)
        alertController.addAction(enterAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
