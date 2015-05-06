//
//  ContactsViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 05/04/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class ContactsViewController: UITableViewController {
	//TODO: add sections
	
    @IBOutlet var searchBar: UISearchBar!

    @IBAction func starTapGestureRecognizer(sender: AnyObject) {
        //Determine the rowindex via the touch point 
        let tapPoint: CGPoint = sender.locationInView(self.tableView)
        let selectedIndex = self.tableView.indexPathForRowAtPoint(tapPoint)
        let contact = contacts.registeredContacts[selectedIndex!.row]
        contact.favorite = !contact.favorite
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // To hide search bar:
        self.tableView.setContentOffset(CGPointMake(0, searchBar.frame.size.height), animated: false)
        
        //Hide additional gridlines, and set gray background for footer
        self.tableView.tableFooterView = UIView(frame:CGRectZero)
        self.tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return contacts.registeredContacts.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("favoriteRow", forIndexPath: indexPath) as! ContactCell
        
        //this class is not key value coding-compliant for the key favoritesTableView.'

        // Configure the cell...
        let contact = contacts.registeredContacts[indexPath.row]
        cell.markup(contact)
        
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



    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {


		if segue.identifier == "contact" {
			//make sure that the segue is going to secondViewController
			let selectedIndex : NSIndexPath = self.tableView.indexPathForSelectedRow()!
			let destVC = segue.destinationViewController as! ContactViewController
			destVC.contact = contacts.registeredContacts[selectedIndex.row]
		}
    }

	
    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool // return NO to not become first responder
    {
        //contactsTableView.clear()
        //reload_transactions(searching: true) //want to show search instructions
        
        return true
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar!) // called when text starts editing
    {
        
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar!) -> Bool // return NO to not resign first responder
    {
        return true
    }
    
    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) // called when text changes (including clear)
    {
        println("search typed")
    }
    
    func searchBarSearchButtonClicked( searchBar: UISearchBar!)
    {
        println("searched")
        
        //get new results
        /*transactions.get(searchBar.text){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                displayError(error_msg!, self)
            }
        }*/
        
        //reload_transactions(loading: true) //want to show spinner
    }
    
    func searchBarCancelButtonClicked( searchBar: UISearchBar!)
    {
        //To hide searchbar
        searchBar.text = ""
        searchBar.resignFirstResponder()
        let y = self.tableView!.contentOffset.y + searchBar!.frame.height
        let newContentOffset = CGPoint(x:0, y: y)
        self.tableView.setContentOffset(newContentOffset, animated: true)
        
        //self.transactionsTableView.scrollRectToVisible(CGRectMake(0, 44,0,0), animated: true)
        
        /*transactions.get(""){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                displayError(error_msg!, self)
            }
        }*/
        
        //reload_transactions(loading: true) //want to show spinner
    }

}
