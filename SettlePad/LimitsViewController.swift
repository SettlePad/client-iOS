//
//  LimitsViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 05/09/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class LimitsViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource   {

	var contact:Contact! = nil
	var sortedCurrencies: [Currency] = []
	var selectedCurrency: Currency = Currency.EUR
	
    @IBOutlet var tableView: UITableView!
	@IBOutlet var formCurrency: PickerButton!
	@IBOutlet var formAmount: UITextField!
	@IBOutlet var formSaveButton: UIButton!
	
	@IBAction func formCurrencyAction(sender: PickerButton) {
		sender.becomeFirstResponder()
	}
	
	@IBAction func formAmountEditingChanged(sender: AnyObject) {
		validateForm(true, finalCheck: false)
	}
	
	@IBAction func add(sender: AnyObject) {
        if validateForm(false, finalCheck: true) {
            let limitAmount = formAmount.text!.toDouble()!
			contact.addLimit(selectedCurrency, limit: limitAmount)
            
            //Clean out the form, set focus on recipient
            tableView.reloadData()
            formAmount.text = ""
            //formAmount.becomeFirstResponder()
        }
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		//Hide additional gridlines, and set gray background for footer
		self.tableView.tableFooterView = UIView(frame:CGRectZero)
		self.tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
		
		//Sort currencies
		sortedCurrencies = Currency.allValues.sort({(left: Currency, right: Currency) -> Bool in left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
		
		//Link currency picker to delegate and datasource functions below
		formCurrency.modInputView.dataSource = self
		formCurrency.modInputView.delegate = self
		
		//Set currency picker to user's default currency
		let row: Int? = sortedCurrencies.indexOf(activeUser!.defaultCurrency)
		if row != nil {
			formCurrency.modInputView.selectRow(row!, inComponent: 0, animated: false)
			selectedCurrency = activeUser!.defaultCurrency
			formCurrency.setTitle(activeUser!.defaultCurrency.rawValue, forState: UIControlState.Normal)
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
		
		if formAmount.text!.toDouble() != nil {
			formAmount.backgroundColor = nil
			formAmount.textColor = nil
		} else {
			isValid = false
			if finalCheck {
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
		return contact.limits.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Limit", forIndexPath: indexPath) 
		
		// Configure the cell...
		cell.textLabel?.text = contact.limits[indexPath.row].currency.rawValue
		cell.detailTextLabel?.text = contact.limits[indexPath.row].limit.format(".2")
		
		return cell
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			// Delete the row from the data source
			contact.removeLimit(contact.limits[indexPath.row].currency, updateServer: true)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		}
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let currency = contact.limits[indexPath.row].currency
		
		//show Action sheet
		let actionSheetController: UIAlertController = UIAlertController(title: "Delete currency limit", message: "Do you want to delete the limit set for "+currency.rawValue+"?", preferredStyle: .Alert)
		
		let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
			//Just dismiss the action sheet
		}
		actionSheetController.addAction(cancelAction)
		
		let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
			self.contact.removeLimit(currency, updateServer: true)
			self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		}
		actionSheetController.addAction(deleteAction)
		
		
		//Present the AlertController
		self.presentViewController(actionSheetController, animated: true, completion: nil)
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		formAmount.becomeFirstResponder() //If done earlier (eg. at viewWillAppear), the layouting is not done yet and keyboard will pop up before that. As that triggers an animated re-layouting, width-changes can also be seen animated. Can also do a self.view.layoutIfNeeded() before this line
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
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		return sortedCurrencies[row].toLongName()
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
	{
		formCurrency.setTitle(sortedCurrencies[row].rawValue, forState: UIControlState.Normal)
		selectedCurrency = sortedCurrencies[row]
	}
	
	func donePicker () {
		//formCurrency.resignFirstResponder()
		formAmount.becomeFirstResponder()
	}
}

