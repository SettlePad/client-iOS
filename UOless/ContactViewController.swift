//
//  ContactViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 05/05/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

// See http://www.nomtek.com/working-with-pickers/

import UIKit

class ContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
	var contact:Contact! = nil
	
	@IBOutlet var nameText: UITextField!
	@IBOutlet var emailsLabel: UILabel!
	@IBOutlet var limitsTable: UITableView!
	@IBOutlet var limitCurrencyButton: PickerButton!
    @IBAction func limitCurrencyButtonAction(sender: PickerButton) {
		sender.becomeFirstResponder()
	}
	@IBAction func addLimitButton(sender: AnyObject) {
		//contact.addLimit(<#currency: Currency#>, limit: limitLimitText)
	}
	
	
	var sortedCurrencies: [Currency] = []
	var selectedCurrency: Currency = Currency.EUR
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		if contact.friendlyName != "" {
			nameText.text = contact.friendlyName
		} else {
			nameText.text = contact.name
		}
		nameText.placeholder = contact.name
		emailsLabel.text = "\r\n".join(contact.identifiers)
		
		//Sort currencies
		sortedCurrencies = Currency.allValues.sorted({(left: Currency, right: Currency) -> Bool in left.toLongName().localizedCaseInsensitiveCompare(right.toLongName()) == NSComparisonResult.OrderedDescending})
		
		//Link currency picker to delegate and datasource functions below
		limitCurrencyButton.modInputView.dataSource = self
		limitCurrencyButton.modInputView.delegate = self
		
		//Set currency picker to user's default currency
		let row: Int? = find(sortedCurrencies,user!.defaultCurrency)
		if row != nil {
			limitCurrencyButton.modInputView.selectRow(row!, inComponent: 0, animated: false)
			selectedCurrency = user!.defaultCurrency
			limitCurrencyButton.setTitle(user!.defaultCurrency.rawValue, forState: UIControlState.Normal)
		}
		
		//Hide additional gridlines
		limitsTable.tableFooterView = UIView(frame:CGRectZero)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return contact.limits.count
    }

	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("limitCell", forIndexPath: indexPath) as! UITableViewCell
		
		// Configure the cell...
		let limit = contact.limits[indexPath.row] as Limit
		let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
		cell.textLabel!.text = limit.currency.rawValue + " " + limit.limit.format(doubleFormat)

        return cell
    }
	

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

	
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
		limitCurrencyButton.setTitle(sortedCurrencies[row].rawValue, forState: UIControlState.Normal)
		selectedCurrency = sortedCurrencies[row]
	}
	
	func checkLimitForm(finalCheck: Bool, whileEditing: Bool) {
		var isValid = true
		var hasGivenFirstResponder = false
		if let parsed = limitLimitText.text.toDouble() {
			limitLimitText.backgroundColor = nil
			limitLimitText.textColor = nil
		} else {
			isValid = false
			if finalCheck || (limitLimitText.text != "" && !whileEditing) {
				limitLimitText.backgroundColor = Colors.danger.backgroundToUIColor()
				limitLimitText.textColor = Colors.danger.textToUIColor()
				if (!hasGivenFirstResponder && finalCheck) {
					limitLimitText.becomeFirstResponder()
					hasGivenFirstResponder = true
				}
			}
		}
	}
}

