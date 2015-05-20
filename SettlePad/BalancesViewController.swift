//
//  BalancesViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class BalancesViewController: UITableViewController {
	//TODO: add footer like in transactions
	//TODO: clean up, looks ugly
	
	var balancesRefreshControl:UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		//Add pull to refresh
		self.balancesRefreshControl = UIRefreshControl()
		self.balancesRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.balancesRefreshControl.addTarget(self, action: "refreshBalances", forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(balancesRefreshControl)
		
		//Hide additional gridlines, and set gray background for footer
		self.tableView.tableFooterView = UIView(frame:CGRectZero)
		
		//refresh Balances
		refreshBalances()
		balancesRefreshControl.beginRefreshing()
		
		//
		
		//Set section header height to dynamic
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 60
    }
	
	func refreshBalances() {
		balances.updateBalances() {()->() in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.tableView.reloadData()
			})
			self.balancesRefreshControl.endRefreshing()
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return balances.sortedCurrencies.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return balances.getBalancesForCurrency(balances.sortedCurrencies[section]).count
    }

	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let  headerCell = tableView.dequeueReusableCellWithIdentifier("Header") as! BalanceHeaderCell
		//headerCell.backgroundColor = UIColor.cyanColor()
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
	}
	
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Balance", forIndexPath: indexPath) as! UITableViewCell
		let balance = balances.getBalancesForCurrency(balances.sortedCurrencies[indexPath.section])[indexPath.row] //of type Balance

		// Configure the cell...
		if balance.contact.friendlyName != "" {
			cell.textLabel?.text = balance.contact.friendlyName
		} else {
			cell.textLabel?.text = balance.contact.name
		}
		
		let doubleFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
		cell.detailTextLabel?.text = balance.currency.rawValue + " " + balance.balance.format(doubleFormat)

		if balance.balance < 0 {
			cell.detailTextLabel?.textColor = Colors.gray.textToUIColor()
		} else {
			cell.detailTextLabel?.textColor = Colors.success.textToUIColor()
		}

		//TODO: add indicator for unprocessed UOmes
		
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

}

class BalanceHeaderCell : UITableViewCell {
	@IBOutlet var currencyLabel: UILabel!
	@IBOutlet var getPayLabel: UILabel!
	@IBOutlet var balanceLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
}
