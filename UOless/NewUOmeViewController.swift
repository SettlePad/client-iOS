//
//  NewUOmeViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 01/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class NewUOmeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource  {
    var footer = NewUOmeFooterView(frame: CGRectMake(0, 0, 320, 44))
    var addressBookFooter = NewUOmeAddressBook(frame: CGRectMake(0, 0, 320, 44))

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
    
    var transactions = [Transaction]()

    enum State {
        case Overview
        case NewUOme
    }
    
    var contactIdentifiers = [Dictionary<String,String>]() //Name, Identifier
    
    var state: State = .Overview
    
    @IBAction func saveUOme(sender: AnyObject) {
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
    
    @IBAction func viewTapped(sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    @IBOutlet var tableSaveContraint: NSLayoutConstraint! //table to Save button
    
    @IBAction func formToEditingChanged(sender: AnyObject) {
        validateForm(true)
        
        //If not-empty, show suggestions
        if formTo.text != "" {
            switchState(.NewUOme)
            getMatchedContactIdentifiers(formTo.text)
            self.newUOmeTableView.reloadData()
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
        } else {
            formDescription.hidden = true
            formType.hidden = true
            formCurrency.hidden = true
            formAmount.hidden = true
            formSaveButton.hidden = true
            
            tableSaveContraint.active = false
            
            addressBookFooter.setNeedsDisplay()
            newUOmeTableView.tableFooterView = addressBookFooter
        }
        
        newUOmeTableView.reloadData()
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
        //newUOmeTableView.tableFooterView = UIView(frame:CGRectZero)
        //self.footer.setNeedsDisplay()
        footer.setNeedsDisplay()
        newUOmeTableView.tableFooterView = footer
        formTo.becomeFirstResponder()
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
        return true
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
