//
//  ContactsViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 05/04/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import UIKit

class ContactsViewController: UITableViewController {	
    @IBOutlet var searchBar: UISearchBar!

    @IBAction func starTapGestureRecognizer(sender: AnyObject) {
        //Determine the rowindex via the touch point 
        let tapPoint: CGPoint = sender.locationInView(self.tableView)
        let selectedIndex = self.tableView.indexPathForRowAtPoint(tapPoint)
        let contact = contacts.registeredContacts[selectedIndex!.row]
        contact.favorite = !contact.favorite
        self.tableView.reloadData()
    }
	
	// custom type to represent table sections
	class Section {
		var contacts: [Contact] = []
		
		func addContact(contact: Contact) {
			self.contacts.append(contact)
		}
	}
	
	// `UIKit` convenience class for sectioning a table
	let collation = UILocalizedIndexedCollation.currentCollation()
		as! UILocalizedIndexedCollation
	
	// table sections
	var sections: [Section] {
		// return if already initialized
		if self._sections != nil {
			return self._sections!
		}
		
		// create empty sections
		var sections = [Section]()
		for i in 0..<self.collation.sectionIndexTitles.count {
			sections.append(Section())
		}
		
		
		// put each currency in a section
		for contact in contacts.registeredContacts {
			let section = self.collation.sectionForObject(contact, collationStringSelector: "friendlyName")
			sections[section].addContact(contact)
		}
		
		// sort each section
		for section in sections {
			section.contacts = self.collation.sortedArrayFromArray(section.contacts, collationStringSelector: "friendlyName") as! [Contact]
		}
		
		self._sections = sections
		
		return self._sections!
	}
	var _sections: [Section]?
	
	var contactsRefreshControl:UIRefreshControl!

	
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
        //self.tableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
		
		//Add pull to refresh
		self.contactsRefreshControl = UIRefreshControl()
		self.contactsRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.contactsRefreshControl.addTarget(self, action: "refreshContacts", forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(contactsRefreshControl)
		
    }
	
	func refreshContacts() {
		contacts.updateContacts() {()->() in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.tableView.reloadData()
			})
			self.contactsRefreshControl.endRefreshing()
		}
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}
	

	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
		return self.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.sections[section].contacts.count
	}

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("favoriteRow", forIndexPath: indexPath) as! ContactCell
        
        //this class is not key value coding-compliant for the key favoritesTableView.'

        // Configure the cell...
		let contact = self.sections[indexPath.section].contacts[indexPath.row]

        cell.markup(contact)

		
        return cell
    }
    
	/* section headers appear above each `UITableView` section */
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
		// do not display empty `Section`s
		if !self.sections[section].contacts.isEmpty {
			return self.collation.sectionTitles[section] as! String
		}
		return "" //Only works correct if table style is plain, otherwise height of the next section header will be too big
	}
	
	/* section index titles displayed to the right of the `UITableView` */
	override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject] {
		return self.collation.sectionIndexTitles
	}
	
	override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
		return self.collation.sectionForSectionIndexTitleAtIndex(index)
	}


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
