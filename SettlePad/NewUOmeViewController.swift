//
//  NewUOmeViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 01/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

protocol NewUOmeModalDelegate {
    func transactionsPosted(controller:NewUOmeViewController)
	func transactionsPostCompleted(controller:NewUOmeViewController, error_msg: String?)
}

class NewUOmeViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource   {
	
    let footer = NewUOmeFooterView(frame: CGRectMake(0, 0, 320, 44))
    var addressBookFooter = UINib(nibName: "NewUOmeAddressBook", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! NewUOmeAddressBook
    
    var delegate:NewUOmeModalDelegate! = nil
	var sortedCurrencies: [Currency] = []
	var selectedCurrency: Currency = Currency.EUR
    
    @IBOutlet var newUOmeTableView: UITableView!
    
    @IBAction func closeView(sender: AnyObject) {
        if state == .Overview {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            formTo.text = ""
            switchState(.Overview)
        }

    }
    
    @IBOutlet var sendButton: UIBarButtonItem!
    
    @IBAction func sendUOmes(sender: AnyObject) {
        if formTo.text != "" {
            saveUOme()
        }
        
        if newTransactions.count > 0 {
            //Post
            transactions.post(newTransactions) { (succeeded: Bool, error_msg: String?) -> () in
                if succeeded == false {
					self.delegate.transactionsPostCompleted(self, error_msg: error_msg!)
				} else {
					self.delegate.transactionsPostCompleted(self, error_msg: nil)
				}

            }
            
            //Go to transactions
            
            delegate.transactionsPosted(self)
            self.dismissViewControllerAnimated(true, completion: nil)

        }
    }
    @IBAction func formCurrencyAction(sender: PickerButton) {
		sender.becomeFirstResponder()
    }
    
    @IBOutlet var formTo: UITextField!
    @IBOutlet var formDescription: UITextField!
    @IBOutlet var formType: UISegmentedControl!
    @IBOutlet var formCurrency: PickerButton!
    @IBOutlet var formAmount: UITextField!
    @IBOutlet var formSaveButton: UIButton!
    
    @IBOutlet var tableBottomConstraint: NSLayoutConstraint!
    
    var newTransactions = [Transaction]()

    enum State {
        case Overview //show all new transactions
        case NewUOme //show suggestions for email address
    }
    
    var matchedContactIdentifiers = [Identifier]() //Name, Identifier
    
    var state: State = .Overview
    var actInd: UIActivityIndicatorView = UIActivityIndicatorView()

    
    
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
        validateForm(true, finalCheck: false)
        
        //If not-empty, show suggestions
        if formTo.text != "" {
            getMatchedContactIdentifiers(formTo.text)
            switchState(.NewUOme)
        } else {
            switchState(.Overview)
        }
    }

    @IBAction func formToEditingDidEnd(sender: AnyObject) {
        validateForm(false, finalCheck: false)

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
            actInd.removeFromSuperview()

            formDescription.hidden = false
            formType.hidden = false
            formCurrency.hidden = false
            formAmount.hidden = false
            formSaveButton.hidden = false
            
            tableSaveContraint.active = true
            
            sendButton.enabled = true
            
            footer.setNeedsDisplay()
            newUOmeTableView.tableFooterView = footer
            
            newUOmeTableView.allowsSelection = false
            
            dispatch_async(dispatch_get_main_queue(), {
                self.newUOmeTableView.reloadData()
            })
        } else if (self.state == .NewUOme){
            actInd.removeFromSuperview()

            formDescription.hidden = true
            formType.hidden = true
            formCurrency.hidden = true
            formAmount.hidden = true
            formSaveButton.hidden = true
            
            tableSaveContraint.active = false
            
            sendButton.enabled = false
            
            layoutAddressBookFooter()
            addressBookFooter.setNeedsDisplay()
            newUOmeTableView.tableFooterView = addressBookFooter
            
            newUOmeTableView.allowsSelection = true
            
            dispatch_async(dispatch_get_main_queue(), {
                self.newUOmeTableView.reloadData()
            })

        }
  
    }
    

    
    func layoutAddressBookFooter() {
        addressBookFooter.frame.size.width = newUOmeTableView.frame.width
        addressBookFooter.detailLabel.preferredMaxLayoutWidth = newUOmeTableView.frame.width - 40 //margin of 20 left and right

        addressBookFooter.frame.size.height = addressBookFooter.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height //Only works if preferred width is set for the objects that have variable height
    }
    
    @IBAction func formDescriptionEditingChanged(sender: AnyObject) {
        validateForm(true,finalCheck: false)
    }
    
    @IBAction func formAmountEditingChanged(sender: AnyObject) {
        validateForm(true, finalCheck: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //newUOmeTableView.rowHeight = UITableViewAutomaticDimension
        
        switchState(.Overview)
        
        addressBookFooter.footerUpdated = {(sender) in
            self.addressBookFooter = UINib(nibName: "NewUOmeAddressBook", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! NewUOmeAddressBook
            self.layoutAddressBookFooter()
            
            dispatch_async(dispatch_get_main_queue(), {
                self.newUOmeTableView.tableFooterView = self.addressBookFooter
            })
            
            dispatch_async(dispatch_get_main_queue(), {
                self.newUOmeTableView.reloadData()
            })
        }
		
		//Sort currencies
		sortedCurrencies = Currency.allValues.sorted({(left: Currency, right: Currency) -> Bool in left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
		
		//Link currency picker to delegate and datasource functions below
		formCurrency.modInputView.dataSource = self
		formCurrency.modInputView.delegate = self
		
		//Set currency picker to user's default currency
		let row: Int? = find(sortedCurrencies,user!.defaultCurrency)
		if row != nil {
			formCurrency.modInputView.selectRow(row!, inComponent: 0, animated: false)
			selectedCurrency = user!.defaultCurrency
			formCurrency.setTitle(user!.defaultCurrency.rawValue, forState: UIControlState.Normal)
		}
		
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateForm (whileEditing: Bool, finalCheck: Bool) -> Bool {
        var isValid = true
        var hasGivenFirstResponder = false
        
        /*Could also color the border, with
            formTo.layer.borderWidth = 1.0
            formTo.layer.borderColor = Colors.danger.textToUIColor().CGColor
        */
        
        if formTo.text.isEmail() {
            formTo.backgroundColor = nil
            formTo.textColor = nil
        } else {
            isValid = false
            if finalCheck || (formTo.text != "" && !whileEditing) {
                formTo.backgroundColor = Colors.danger.backgroundToUIColor()
                formTo.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder && finalCheck) {
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
            if finalCheck {
                formDescription.backgroundColor = Colors.danger.backgroundToUIColor()
                formDescription.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder && finalCheck) {
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
            if finalCheck || (formDescription.text != "" && !whileEditing) {
                formAmount.backgroundColor = Colors.danger.backgroundToUIColor()
                formAmount.textColor = Colors.danger.textToUIColor()
                if (!hasGivenFirstResponder && finalCheck) {
                    formAmount.becomeFirstResponder()
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
            return newTransactions.count
        } else {
            return matchedContactIdentifiers.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (self.state == .Overview) {
            //Show draft UOme's
            let cell = tableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as! TransactionsCell
            
            // Configure the cell...
            cell.markup(newTransactions[indexPath.row])
            return cell
        } else {
            //show contacts
            let cell = tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as! UITableViewCell
            
            // Configure the cell...
            let contactIdentifier = matchedContactIdentifiers[indexPath.row]
			if contactIdentifier.contact.friendlyName != "" {
				cell.textLabel?.text = contactIdentifier.contact.friendlyName
			} else {
				cell.textLabel?.text = contactIdentifier.contact.name
			}

            cell.detailTextLabel?.text =  contactIdentifier.identifierStr
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
            let contactIdentifier = matchedContactIdentifiers[indexPath.row]
            formTo.text = contactIdentifier.identifierStr
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
        
        //Required to have dynamic row height
        newUOmeTableView.estimatedRowHeight = 70
        newUOmeTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        formTo.becomeFirstResponder() //If done earlier (eg. at viewWillAppear), the layouting is not done yet and keyboard will pop up before that. As that triggers an animated re-layouting, width-changes can also be seen animated. Can also do a self.view.layoutIfNeeded() before this line
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
        if validateForm(false, finalCheck: true) {
            var amount: Double
            if (formType.selectedSegmentIndex == 0) {
                amount = formAmount.text.toDouble()!
            } else {
                amount = -1*formAmount.text.toDouble()!
            }
            
            var transaction = Transaction(
				counterpart: contacts.getContactByIdentifier(formTo.text),
				identifier: formTo.text,
                description: formDescription.text,
                currency: selectedCurrency,
                amount: amount
            )
            newTransactions.append(transaction)
            
            //Clean out the form, set focus on recipient
            newUOmeTableView.reloadData()
            footer.setNeedsDisplay()
            newUOmeTableView.tableFooterView = footer
            formTo.text = ""
            formTo.becomeFirstResponder()
        }
    }
    
    func deleteTransaction(index:Int){
        newTransactions.removeAtIndex(index)
        newUOmeTableView.reloadData()
        footer.setNeedsDisplay()
        newUOmeTableView.tableFooterView = footer
        
    }
    
    func getMatchedContactIdentifiers(needle: String){
        matchedContactIdentifiers.removeAll()
        for contactIdentifier in contacts.contactIdentifiers {
            if (contactIdentifier.identifierStr.lowercaseString.rangeOfString(needle.lowercaseString) != nil || contactIdentifier.contact.name.lowercaseString.rangeOfString(needle.lowercaseString) != nil || contactIdentifier.contact.friendlyName.lowercaseString.rangeOfString(needle.lowercaseString) != nil) {
                matchedContactIdentifiers.append(contactIdentifier)
            }
        }
    }
	
	// Currency picker delegate
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
	{
		return 1;
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		return sortedCurrencies.count;
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String
	{
		return sortedCurrencies[row].toLongName()
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
	{
		formCurrency.setTitle(sortedCurrencies[row].rawValue, forState: UIControlState.Normal)
		selectedCurrency = sortedCurrencies[row]
	}
	
	func donePicker () {
		formCurrency.resignFirstResponder()
	}
}

class NewUOmeFooterView: UIView {
	override init (frame : CGRect) {
		super.init(frame : frame)
		self.opaque = false //Required for transparent background
	}
	
	/*convenience override init () {
	self.init(frame:CGRectMake(0, 0, 320, 44)) //By default, make a rect of 320x44
	}*/
	
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	
	override func drawRect(rect: CGRect) {
		//To make sure we are not adding one layer of text onto another
		for view in self.subviews {
			view.removeFromSuperview()
		}
		
		
		let footerLabel: UILabel = UILabel(frame: rect)
		footerLabel.textColor = Colors.gray.textToUIColor()
		footerLabel.font = UIFont.boldSystemFontOfSize(11)
		footerLabel.textAlignment = NSTextAlignment.Center
		
		footerLabel.text = "Saved UOmes will be listed here to be all sent at once."
		self.addSubview(footerLabel)
	}
	
}

