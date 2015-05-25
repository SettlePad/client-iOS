//
//  SettingsViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 07/01/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    

    @IBOutlet var nameText: UITextField!
    @IBOutlet var credentialsLabel: UILabel!
    @IBOutlet var currencyLabel: UILabel!
    @IBOutlet var favoritesLabel: UILabel!
	
	var settingsRefreshControl:UIRefreshControl!
	
    @IBAction func viewTapped(sender: AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
    }
    
    @IBAction func nameEdited(sender: UITextField) {
        user?.name = sender.text
    }
    
    @IBAction func logout(sender: AnyObject) {
        api.logout()
        dispatch_async(dispatch_get_main_queue()) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") as! UIViewController
            self.presentViewController(vc, animated: false, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateLabels()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

		//Add pull to refresh
		self.settingsRefreshControl = UIRefreshControl()
		self.settingsRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.settingsRefreshControl.addTarget(self, action: "refreshUserData", forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(settingsRefreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 0
    }*/

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell

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

    
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    
    }
    */
    
    func updateLabels () {
        currencyLabel.text = user?.defaultCurrency.rawValue
        nameText.text = user?.name
        credentialsLabel.text = user?.userIdentifiers.count.description
        favoritesLabel.text = contacts.registeredContacts.count.description
    }
	
	func refreshUserData () {
		user!.updateSettings() { (succeeded: Bool, error_msg: String?) -> () in

			if (succeeded) {
				dispatch_async(dispatch_get_main_queue(), {
					//so it is run now, instead of at the end of code execution
					self.updateLabels()
				})
			} else {
				displayError(error_msg!, self)
			}
			self.settingsRefreshControl.endRefreshing()
		}
	}

}
