//
//  BalancesViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 10/05/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class BalancesViewController: UITableViewController {

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
		
		//refresh Balances
		balancesRefreshControl.beginRefreshing()
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
        return balances.currencies.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return balances.getBalancesForCurrency(balances.sortedCurrencies[section]).count
    }

	/*override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let  headerCell = tableView.dequeueReusableCellWithIdentifier("Header") as CustomHeaderCell
		headerCell.backgroundColor = UIColor.cyanColor()
  
		switch (section) {
		case 0:
			headerCell.headerLabel.text = "Europe";
			//return sectionHeaderView
		case 1:
			headerCell.headerLabel.text = "Asia";
			//return sectionHeaderView
		case 2:
			headerCell.headerLabel.text = "South America";
			//return sectionHeaderView
		default:
			headerCell.headerLabel.text = "Other";
		}
		
		return headerCell
	}*/
	
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

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
