//
//  NewUOmeViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 01/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class NewUOmeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate  {
    //TODO: on keyboard show, tableview should resize!s
    
    let footer = NewUOmeFooterView(frame: CGRectMake(0, 0, 320, 44))
    let addressBookFooter = UINib(nibName: "NewUOmeAdressBook", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as NewUOmeAddressBook

    
    @IBOutlet var newUOmeTableView: UITableView!
    
    @IBAction func closeView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBOutlet var formTo: UITextField!
    @IBOutlet var formDescription: UITextField!
    @IBOutlet var formType: UISegmentedControl!
    @IBOutlet var formCurrency: UIButton!
    @IBOutlet var formAmount: UITextField!
    @IBOutlet var formSaveButton: UIButton!
    
    @IBOutlet var tableBottomConstraint: NSLayoutConstraint!
    
    var transactions = [Transaction]()

    enum State {
        case Overview
        case NewUOme
    }
    
    var contactIdentifiers = [Dictionary<String,String>]() //Name, Identifier
    
    var state: State = .Overview
    
    @IBAction func saveUOme(sender: AnyObject) {
        saveUOme()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if state == .NewUOme {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func viewTapped(sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    @IBOutlet var tableSaveContraint: NSLayoutConstraint! //table to Save button
    
    @IBAction func formToEditingChanged(sender: AnyObject) {
        validateForm(true)
        
        //If not-empty, show suggestions
        if formTo.text != "" {
            getMatchedContactIdentifiers(formTo.text)
            switchState(.NewUOme)
        } else {
            switchState(.Overview)
        }
    }

    @IBAction func formToEditingDidEnd(sender: AnyObject) {
        //Hide suggestions
        if formTo.text != "" {
            switchState(.Overview)
        }
    }
    
    func switchState(explicitState: State?) {
        if let state = explicitState {
            self.state = state
        } else {
            if (self.state == .Overview) {
                self.state = .NewUOme
            } else {
                self.state = .Overview
            }
        }
        
        if (self.state == .Overview) {
            formDescription.hidden = false
            formType.hidden = false
            formCurrency.hidden = false
            formAmount.hidden = false
            formSaveButton.hidden = false
            
            tableSaveContraint.active = true
            
            footer.setNeedsDisplay()
            newUOmeTableView.tableFooterView = footer
            
            newUOmeTableView.allowsSelection = false
        } else {
            formDescription.hidden = true
            formType.hidden = true
            formCurrency.hidden = true
            formAmount.hidden = true
            formSaveButton.hidden = true
            
            tableSaveContraint.active = false
            relayoutAddressBookFooter(nil)
            newUOmeTableView.tableFooterView = addressBookFooter
            
            newUOmeTableView.allowsSelection = true
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.newUOmeTableView.reloadData()
        })
    }
    

    
    func relayoutAddressBookFooter(height: CGFloat?){
        addressBookFooter.frame.size.width = newUOmeTableView.frame.width
         addressBookFooter.detailLabel.preferredMaxLayoutWidth = newUOmeTableView.frame.width - 40 //margin of 20 left and right
        
        if let setHeight = height {
            addressBookFooter.frame.size.height = setHeight
        } else {
            addressBookFooter.frame.size.height = addressBookFooter.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height //Only works if preferred width is set for the objects that have variable height
        }
        addressBookFooter.setNeedsDisplay()
    }
    
    @IBAction func formDescriptionEditingChanged(sender: AnyObject) {
        validateForm(true)
    }
    
    @IBAction func formAmountEditingChanged(sender: AnyObject) {
        validateForm(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        newUOmeTableView.rowHeight = UITableViewAutomaticDimension
        
        switchState(.Overview)
        
        addressBookFooter.footerUpdated = {(sender, height) in
            self.relayoutAddressBookFooter(height)
            dispatch_async(dispatch_get_main_queue(), {
                self.newUOmeTableView.reloadData()
            })
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateForm (whileEditing: Bool) -> Bool {
        var isValid = true
        var hasGivenFirstResponder = false
        
        /*Could also color the border, with
            formTo.layer.borderWidth = 1.0
            formTo.layer.borderColor = Colors.danger.textToUIColor().CGColor
        */
        
        if formTo.text != "" {
            //TODO: check that it is an email address
            formTo.backgroundColor = nil
            formTo.textColor = nil
        } else {
            isValid = false
            if (!whileEditing) {
                formTo.backgroundColor = Colors.danger.backgroundToUIColor()
                formTo.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder) {
                    formTo.becomeFirstResponder()
                    hasGivenFirstResponder = true
                }
            }
        }
        
        if formDescription.text != "" {
            formDescription.backgroundColor = nil
            formDescription.textColor = nil
        } else {
            isValid = false
            if (!whileEditing) {
                formDescription.backgroundColor = Colors.danger.backgroundToUIColor()
                formDescription.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder) {
                    formDescription.becomeFirstResponder()
                    hasGivenFirstResponder = true
                }
                
            }
        }
        
        if let parsed = formAmount.text.toDouble() {
            formAmount.backgroundColor = nil
            formAmount.textColor = nil
        } else {
            isValid = false
            if (!whileEditing) {
                formAmount.backgroundColor = Colors.danger.backgroundToUIColor()
                formAmount.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder) {
                    formDescription.becomeFirstResponder()
                    hasGivenFirstResponder = true
                }
            }
        }
        
        return isValid
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */



    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.state == .Overview) {
            return transactions.count
        } else {
            return contactIdentifiers.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (self.state == .Overview) {
            //Show draft UOme's
            let cell = tableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as TransactionsCell
            
            // Configure the cell...
            cell.markup(transactions[indexPath.row])
            return cell
        } else {
            //show contacts
            let cell = tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as UITableViewCell
            
            // Configure the cell...
            let contactIdentifier = contactIdentifiers[indexPath.row]
            cell.textLabel?.text = contactIdentifier["name"]
            cell.detailTextLabel?.text =  contactIdentifier["identifier"]
            return cell
        }
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Editable or not
        if (self.state == .Overview) {
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //function required to have editable rows
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        //return []
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            self.deleteTransaction(indexPath.row)
        })
        deleteAction.backgroundColor = Colors.danger.textToUIColor()
        return [deleteAction]
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if (self.state == .NewUOme) {
            //Set value as "to"
            let contactIdentifier = contactIdentifiers[indexPath.row]
            formTo.text = contactIdentifier["identifier"]
            switchState(.Overview)
            //goto amount
            if formDescription.text == "" {
                formDescription.becomeFirstResponder()
            } else {
                formAmount.becomeFirstResponder()
            }
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrameNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil) //This will be removed at viewWillDisappear
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        formTo.becomeFirstResponder() //If done earlier (eg. at viewWillAppear), the layouting is not done yet and keyboard will pop up before that. As that triggers an animated re-layouting, width-changes can also be seen animated. Can also do a self.view.layoutIfNeeded() before this line
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    func keyboardWillChangeFrameNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve << 16))
        
        /*
        if (CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) > 0) {
            //will show
        } else {
            //will hide
        }
        */
        
        tableBottomConstraint.constant = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame)
        
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: .BeginFromCurrentState | animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil
        )
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        //textfields that should trigger this need to have their delegate set to the viewcontroller
        
        if (textField!.restorationIdentifier == "to") {
            //goto description
            formDescription.becomeFirstResponder()
        } else if (textField!.restorationIdentifier == "description") {
            //goto amount
            formAmount.becomeFirstResponder()
        } else if (textField!.restorationIdentifier == "amount") {
            saveUOme()
        }
        return true;
    }
    
    func saveUOme() {
        if validateForm(false) {
            var amount: Double
            if (formType.selectedSegmentIndex == 0) {
                amount = formAmount.text.toDouble()!
            } else {
                amount = -1*formAmount.text.toDouble()!
            }
            
            var transaction = Transaction(
                counterpart_name: formTo.text,
                description: formDescription.text,
                currency: formCurrency.titleLabel!.text!,
                amount: amount
            )
            transactions.append(transaction)
            
            //Clean out the form, set focus on recipient
            newUOmeTableView.reloadData()
            footer.setNeedsDisplay()
            newUOmeTableView.tableFooterView = footer
            formTo.text = ""
            formTo.becomeFirstResponder()
        }
    }
    
    func deleteTransaction(index:Int){
        transactions.removeAtIndex(index)
        newUOmeTableView.reloadData()
        footer.setNeedsDisplay()
        newUOmeTableView.tableFooterView = footer
        
    }
    
    func getMatchedContactIdentifiers(needle: String){
        contactIdentifiers.removeAll()
        for contact in contacts.contacts {
            for identifier in contact.identifiers {
                if (identifier.lowercaseString.rangeOfString(needle.lowercaseString) != nil || contact.name.lowercaseString.rangeOfString(needle.lowercaseString) != nil) {
                    contactIdentifiers.append(["name":contact.name,"identifier":identifier])
                }
            }
        }
    }
}
