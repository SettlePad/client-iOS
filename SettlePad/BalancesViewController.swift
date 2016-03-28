//
//  BalancesViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class BalancesViewController: UITableViewController, NewUOmeModalDelegate, ContactsViewControllerDelegate {
	var balancesRefreshControl:UIRefreshControl!
	var footer = BalancesFooterView(frame: CGRectMake(0, 0, 320, 44))
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showUOmeSegueFromBalances" {
			let navigationController = segue.destinationViewController as! UINavigationController
			let vc = navigationController.viewControllers[0] as! NewUOmeViewController
			vc.delegate = self
		}
	}
	
	func transactionsPosted(controller:NewUOmeViewController) {
		controller.dismissViewControllerAnimated(true, completion: nil)
		//do not reload until post completed
	}
	
	func reloadContent(error_msg: String?) {
		//When coming from ContactViewController
		if error_msg != nil {
			displayError(error_msg!, viewController: self)
		}
		self.tableView.reloadData()
	}
	
	func transactionsPostCompleted(controller:NewUOmeViewController, error_msg: String?) {
		//Goto login screen
		if error_msg != nil {
			displayError(error_msg!, viewController: self)
			if (activeUser == nil) {
				dispatch_async(dispatch_get_main_queue()) {
					let storyboard = UIStoryboard(name: "Main", bundle: nil)
					let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") 
					self.presentViewController(vc, animated: false, completion: nil)
				}
			} else {
				self.refreshBalances()
			}
		} else {
			self.refreshBalances()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		//Add pull to refresh
		self.balancesRefreshControl = UIRefreshControl()
		self.balancesRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.balancesRefreshControl.addTarget(self, action: #selector(BalancesViewController.refreshBalances), forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(balancesRefreshControl)
		
		//Hide additional gridlines, and set gray background for footer
		//self.tableView.tableFooterView = UIView(frame:CGRectZero)
		

    }
	
	override func viewWillAppear(animated: Bool) {
		//refresh Balances
		refreshBalances()
		balancesRefreshControl.beginRefreshing()
	}
	
	func refreshBalances() {
		activeUser!.balances.updateBalances(
			{
				self.footer.no_results = (activeUser!.balances.sortedCurrencies.count == 0)
				dispatch_async(dispatch_get_main_queue(), {
					//so it is run now, instead of at the end of code execution
					self.tableView.reloadData()
					
					self.balancesRefreshControl.endRefreshing()
					self.footer.setNeedsDisplay()
					self.tableView.tableFooterView = self.footer
				})
			},
			failure: {error in
				displayError(error.errorText, viewController: self)
			}
			
		)
	}
	



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return activeUser!.balances.sortedCurrencies.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return activeUser!.balances.getBalancesForCurrency(activeUser!.balances.sortedCurrencies[section]).count
    }

	/*override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let  headerCell = tableView.dequeueReusableCellWithIdentifier("Header") as! BalanceHeaderCell
		let currency = balances.sortedCurrencies[section]
		headerCell.currencyLabel.text = currency.toLongName()
		let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
		
		if let currencySummary =  balances.getSummaryForCurrency(currency) {
			headerCell.getPayLabel.text = "get "+currency.rawValue+" "+currencySummary.get.format(doubleFormat)+", pay "+currency.rawValue+" " + (currencySummary.owe * -1).format(doubleFormat)
			headerCell.balanceLabel.text = currency.rawValue+" "+currencySummary.balance.format(doubleFormat)
			
			if currencySummary.balance < 0 {
				headerCell.balanceLabel.textColor = Colors.gray.textToUIColor()
			} else {
				headerCell.balanceLabel.textColor = Colors.success.textToUIColor()
			}

		} else {
			headerCell.getPayLabel.text = "Unknown"
			headerCell.balanceLabel.text = "Unknown"
			
		}
		
		return headerCell
	}*/
	
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		/*if balances.sortedCurrencies.count < section {
			return "Refresh please" //To overcome bad access
		} else {*/
			let currency = activeUser!.balances.sortedCurrencies[section]

			if let currencySummary =  activeUser!.balances.getSummaryForCurrency(currency) {
				let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
				//return currency.rawValue+" "+currencySummary.balance.format(doubleFormat)+" (get "+currencySummary.get.format(doubleFormat)+", owe " + (currencySummary.owe * -1).format(doubleFormat)+")"
				return currency.rawValue+" "+currencySummary.balance.format(doubleFormat)
			} else {
				return "Unknown"
			}
		//}
	}
	
	override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let headerView = view as! UITableViewHeaderFooterView
		let currency = activeUser!.balances.sortedCurrencies[section]
		
		if let currencySummary =  activeUser!.balances.getSummaryForCurrency(currency) {
			if currencySummary.balance < 0 {
				headerView.textLabel!.textColor = Colors.gray.textToUIColor()
			} else {
				headerView.textLabel!.textColor = Colors.success.textToUIColor()
			}
		}
		
		//headerView.contentView.backgroundColor = UIColor(red: 0/255, green: 181/255, blue: 229/255, alpha: 1.0) //make the background color light blue
	}
	
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		//TODO: add indicator for memos that are not yet reduced and call it queued
		
		let cell = tableView.dequeueReusableCellWithIdentifier("Balance", forIndexPath: indexPath) as! BalanceCell
		
		let balance = activeUser!.balances.getBalancesForCurrency(activeUser!.balances.sortedCurrencies[indexPath.section])[indexPath.row] //of type Balance
		
		// Configure the cell...
		var balanceName = balance.name
		var balanceFavorite = false
		let identifier: Identifier? = activeUser!.contacts.getIdentifier(balance.identifierStr)
		if(identifier != nil) {
			balanceName = identifier!.resultingName
			if let balanceContact = identifier?.contact {
				balanceFavorite = balanceContact.favorite
			}
		}
		
		cell.markup(balanceName, currency: balance.currency, balance: balance.balance, favorite: balanceFavorite)
		
		
		return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		//Go to contact view if available, otherwise ask to create a new contact
		let balance = activeUser!.balances.getBalancesForCurrency(activeUser!.balances.sortedCurrencies[indexPath.section])[indexPath.row] //of type Balance
		let identifier: Identifier? = activeUser!.contacts.getIdentifier(balance.identifierStr)

		dispatch_async(dispatch_get_main_queue()) {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let navigationController = storyboard.instantiateViewControllerWithIdentifier("ContactNavigationController") as! UINavigationController
			let destVC = navigationController.viewControllers[0] as! ContactViewController
			if let balanceContact = identifier?.contact {
				//Go to balanceContact
				destVC.contact = balanceContact
				destVC.delegate = self
				destVC.modalForEditing = true //So display close instead of save and cancel
			} else {
				//Create a new contact
				destVC.contact = Contact(name: balance.name, friendlyName: "", registered: true, favorite: true, autoAccept: AutoAccept.Manual, identifiers: [balance.identifierStr], propagatedToServer: false, user: activeUser!)
			}
			destVC.delegate = self

			self.presentViewController(navigationController, animated: true, completion: nil)
		}
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

}


class BalancesFooterView: UIView {
	var no_results = true
	
	override init (frame : CGRect) {
		super.init(frame : frame)
		self.opaque = false //Required for transparent background
	}
	
	/*convenience override init () {
	self.init(frame:CGRectMake(0, 0, 320, 44)) //By default, make a rect of 320x44
	}*/
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	
	override func drawRect(rect: CGRect) {
		//To make sure we are not adding one layer of text onto another
		for view in self.subviews {
			view.removeFromSuperview()
		}
		
		
		if self.no_results {
			let footerLabel: UILabel = UILabel(frame: rect)
			footerLabel.textColor = Colors.gray.textToUIColor()
			footerLabel.font = UIFont.boldSystemFontOfSize(11)
			footerLabel.textAlignment = NSTextAlignment.Center
			
			footerLabel.text = "You do not owe anyone, nor do they owe you!"
			self.addSubview(footerLabel)
		}
	}
}

class BalanceCell: UITableViewCell {
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var amountLabel: UILabel!
	@IBOutlet var statusImage: UIImageView!
	
	//var contact: Contact?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func markup(name: String, currency: Currency, balance: Double, favorite: Bool){

		let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
		amountLabel.text = currency.rawValue + " " + balance.format(doubleFormat)
		
		if balance < 0 {
			amountLabel.textColor = Colors.gray.textToUIColor()
		} else {
			amountLabel.textColor = Colors.success.textToUIColor()
		}
		
		if favorite {
			statusImage.hidden = true
		} else {
			statusImage.hidden = false
		}
		
		nameLabel.text = name
	}
	
	
}