//
//  ContactViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 11/08/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

protocol ContactViewControllerDelegate {
	func reloadContent()
}

class ContactViewController: UITableViewController, ContactViewControllerDelegate {
	func reloadContent() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.title = self.contact.resultingName
			self.tableView.reloadData()
		})
	}
	
	var contact:Contact! = nil
	var modalForEditing = false //If set to true and self.isModal(), save button will be hidden and cancel will be named closed
	
	var forEditing: Bool {
		get {
			if self.isModal() && !modalForEditing {
				return false
			} else {
				return true
			}
		}
	}
	
	var delegate:ContactsViewControllerDelegate! = nil

    @IBOutlet var saveBarButton: UIBarButtonItem! //Should only be used on modal presentation
    @IBOutlet var cancelBarButton: UIBarButtonItem! //Should only be used on modal presentation
    @IBOutlet var fixedEmailGestureRecognizer: UITapGestureRecognizer!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		if(!self.isModal()) {
			//Pushed from contact list, so use back button instead of configured "Save" and "Cancel"
			self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
			self.navigationItem.rightBarButtonItem = nil
		} else if modalForEditing {
			cancelBarButton.title = "Close"
			self.navigationItem.rightBarButtonItem = nil
		} else {
			fixedEmailGestureRecognizer.enabled = false //When adding a contact, the deleteContact function should not be triggered when pressing the email address
		}
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		//Set cell height to dynamic. Note that it also requires a cell.layoutIfNeeded in cellForRowAtIndexPath!
		self.tableView.estimatedRowHeight = 140.0
		self.tableView.rowHeight = UITableViewAutomaticDimension

		reloadContent()
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
		if (forEditing) {
			return 5 //Including delete
		} else {
			return 4 //No delete button
		}

    }
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Name"
		} else if section == 1 {
			return "Email address(es)"
		} else if section == 2 {
			return "Balance allocation"
		} else if section == 3 {
			return "Acceptance of incoming memos"
		} else {
			return nil
		}
		
	}

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
		if section == 0 {
			//Name
			return 1
		} else if section == 1 {
			//Identifier(s)
			if contact.registered {
				return contact.identifiers.count //number of email addresses
			} else {
				return 1
			}
		} else if section == 2 {
			//Defaulter
			return 1
		} else if section == 3 {
			//Auto acceptance
			if contact.autoAccept == .UpToDefinedLimit {
				return 2 //setting + limits bar
			} else {
				return 1 //setting
			}
		} else {
			return 1 //delete
		}
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			//name
			let cell = tableView.dequeueReusableCellWithIdentifier("Name", forIndexPath: indexPath) as! ContactNameCell
			cell.markup(self, contact: contact)
			return cell
		} else if indexPath.section == 1 {
			//identifier(s)
			if contact.registered {
				let cell = tableView.dequeueReusableCellWithIdentifier("EmailFixed", forIndexPath: indexPath) 
				cell.textLabel?.text = contact.identifiers[indexPath.row]
				return cell
			} else {
				let cell = tableView.dequeueReusableCellWithIdentifier("EmailInput", forIndexPath: indexPath) as! ContactEmailInputCell
				cell.markup(self, contact: contact)
				return cell
			}
		} else if indexPath.section == 2 {
			//Defaulter
			let cell = tableView.dequeueReusableCellWithIdentifier("Status", forIndexPath: indexPath) as! ContactDefaulterCell
			cell.markup(contact)
			cell.layoutIfNeeded() //to get right layout given dynamic height
			return cell
		} else if indexPath.section == 3 {
			//Auto acceptance
			if indexPath.row == 0 {
				let cell = tableView.dequeueReusableCellWithIdentifier("Autoacceptance", forIndexPath: indexPath) 
				if contact.autoAccept == .Manual {
					cell.detailTextLabel?.text = "None"
				} else if contact.autoAccept ==  .UpToDefinedLimit {
					cell.detailTextLabel?.text = "Up to limit"
				} else {
					//Automatic
					cell.detailTextLabel?.text = "All"
				}
				return cell
			} else {
				let cell = tableView.dequeueReusableCellWithIdentifier("Limits", forIndexPath: indexPath) 
				cell.detailTextLabel?.text = contact.limits.count.description
				return cell
			}
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("Delete", forIndexPath: indexPath) 
			return cell
		}
		
    }
	

	
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
		return false
    }
	

	/*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

	}
	*/

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

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "autoacceptance" {
			//make sure that the segue is going to secondViewController
			let destVC = segue.destinationViewController as! AcceptMemosViewController
			destVC.contact = contact
		} else if segue.identifier == "limits" {
			//make sure that the segue is going to secondViewController
			let destVC = segue.destinationViewController as! LimitsViewController
			destVC.contact = contact
		}
    }

    @IBAction func cancelContact(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveContact(sender: AnyObject) {
		self.tableView.endEditing(false) //When editing a textbox when the button is pressed, we first want to process the changes of the textbox, before processing the button press
		activeUser!.contacts.addContact(contact, updateServer: true,
			success: {
				self.delegate.reloadContent(nil) //Refresh the contact list in the contacts viewController, so that the spinner for the saved contact is gone
			},
			failure: {error in
				self.delegate.reloadContent(error.errorText)
			}
		)
	
		self.dismissViewControllerAnimated(true, completion: nil)
    }
	
    @IBAction func deleteContact(sender: AnyObject) {
		//show Action sheet
		let actionSheetController: UIAlertController = UIAlertController(title: "Are you sure you want to delete this connection?", message: "New memos from this contract are treated as if received from a stranger.", preferredStyle: .Alert)
		
		let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
			//Just dismiss the action sheet
		}
		actionSheetController.addAction(cancelAction)
		
		let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
			self.contact.deleteContact()
			if (self.isModal()) {
				self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
			} else {
				self.navigationController?.popViewControllerAnimated(true)
			}
		}
		actionSheetController.addAction(deleteAction)
		
		
		//Present the AlertController
		self.presentViewController(actionSheetController, animated: true, completion: nil)

    }
}

class ContactDefaulterCell: UITableViewCell {
	var contact: Contact?

	@IBOutlet var defaulterSwitch: UISwitch!
    @IBAction func defaulterChanged(sender: UISwitch) {
        contact?.setFavorite(!sender.on, updateServer: true)
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	
	func markup(contact: Contact){
		self.contact = contact
		defaulterSwitch.on = !contact.favorite
	}
}

class ContactNameCell: UITableViewCell {
	var delegate:ContactViewControllerDelegate! = nil
	var contact: Contact?
	
	@IBOutlet var nameText: UITextField!
    @IBAction func nameEditingDidEnd(sender: UITextField) {
		contact?.setFriendlyName(sender.text!, updateServer: true)
		//delegate.reloadContent()
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func markup(delegate: ContactViewControllerDelegate, contact: Contact){
		self.delegate = delegate
		self.contact = contact
		nameText.text = contact.resultingName
	}
}

class ContactEmailInputCell: UITableViewCell {
	var delegate:ContactViewControllerDelegate! = nil
	var contact: Contact?
	
    @IBOutlet var emailText: UITextField!
    @IBAction func emailEditingDidEnd(sender: UITextField) {
		if validateInput() {
			contact?.updateServerIdentifier(emailText.text!) { (succeeded: Bool, error_msg: String?) -> () in
				self.delegate.reloadContent()
			}
		}
    }
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func markup(delegate: ContactViewControllerDelegate, contact: Contact){
		self.delegate = delegate
		self.contact = contact
		if contact.identifiers.count > 0 {
			emailText.text = contact.identifiers[0]
			validateInput()
		} else {
			emailText.text = ""
		}
	}
	
	func validateInput() -> Bool {
		if emailText.text!.isEmail() {
			emailText.backgroundColor = nil
			emailText.textColor = nil
			return true
		} else {
			emailText.backgroundColor = Colors.danger.backgroundToUIColor()
			emailText.textColor = Colors.danger.textToUIColor()
			return false
		}
	}
}

