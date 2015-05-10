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
	
    @IBOutlet var starImageView: UIImageView!
    @IBOutlet var limitLimitText: UITextField!
	@IBOutlet var limitCurrencyButton: PickerButton!
    @IBAction func limitCurrencyButtonAction(sender: PickerButton) {
		sender.becomeFirstResponder()
	}
	
    @IBAction func limitLimitEditingChanged(sender: AnyObject) {
		checkLimitForm(false, whileEditing: true)
    }
	
    @IBAction func nameTextEditingDidEnd(sender: AnyObject) {
        contact.friendlyName = nameText.text
    }
	
    @IBAction func starTapGestureRecognizer(sender: AnyObject) {
        //Determine the rowindex via the touch point
        contact.favorite = !contact.favorite
		dispatch_async(dispatch_get_main_queue(), {
			self.updateStar()
		})
    }
	
	@IBAction func addLimitButton(sender: AnyObject) {
		if checkLimitForm(true, whileEditing: false) {
			contact.addLimit(selectedCurrency, limit: limitLimitText.text.toDouble()!, updateServer: true)
			dispatch_async(dispatch_get_main_queue(), {
				self.limitsTable.reloadData()
				self.limitLimitText.text = ""
			})
		}
	}
	
	
	var sortedCurrencies: [Currency] = []
	var selectedCurrency: Currency = Currency.EUR
	
	override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		
		//Kill inset
		// iOS 7:
		limitsTable.separatorStyle = .SingleLine
		limitsTable.separatorInset = UIEdgeInsetsZero
		
		// iOS 8:
		if UITableView.instancesRespondToSelector("setLayoutMargins:") {
			limitsTable.layoutMargins = UIEdgeInsetsZero
		}
		
		limitsTable.layoutIfNeeded()
		
	}
	
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
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		//Set cell height to dynamic
		limitsTable.rowHeight = UITableViewAutomaticDimension
		limitsTable.estimatedRowHeight = 40
		
		updateStar()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("limitCell", forIndexPath: indexPath) as! LimitCell
		
		// Configure the cell...
		let limit = contact.limits[indexPath.row] as Limit
		let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
		cell.limitLabel.text = limit.currency.rawValue + " " + limit.limit.format(doubleFormat)
		//cell.backgroundColor = Colors.danger.backgroundToUIColor()
        return cell
    }
	
	//To kill the inset
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

		// iOS 7:
		cell.separatorInset = UIEdgeInsetsZero
		
		// iOS 8:
		if UITableView.instancesRespondToSelector("setLayoutMargins:") {
			limitsTable.layoutMargins = UIEdgeInsetsZero
			cell.layoutMargins = UIEdgeInsetsZero
			cell.preservesSuperviewLayoutMargins = false
		}
		

	}
	
	func updateStar() {
		if self.contact.favorite {
			self.starImageView.image = UIImage(named: "StarFull")
		} else {
			self.starImageView.image = UIImage(named: "StarEmpty")
		}
	}
	
    // Override to support conditional editing of the table view.
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
	

	
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
			let limit = contact.limits[indexPath.row] as Limit
			contact.removeLimit(limit.currency, updateServer: true)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
		limitCurrencyButton.setTitle(sortedCurrencies[row].rawValue, forState: UIControlState.Normal)
		selectedCurrency = sortedCurrencies[row]
	}
	
	func donePicker () {
		limitCurrencyButton.resignFirstResponder()
	}
	
	func checkLimitForm(finalCheck: Bool, whileEditing: Bool) -> Bool {
		var isValid = true
		var hasGivenFirstResponder = false
		let parsed = limitLimitText.text.toDouble()
		if parsed != nil && parsed >= 0 {
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
		return isValid
	}

}

class LimitCell: UITableViewCell {
	
	
	@IBOutlet var limitLabel: UILabel!
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
}

