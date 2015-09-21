//
//  ContactsViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 05/04/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit

protocol ContactsViewControllerDelegate {
	func reloadContent(error_msg: String?)
}


class ContactsViewController: UITableViewController, ContactsViewControllerDelegate {
	//TODO: with refreshControl spinning and no connection to server, all section heads are screwed up

	var serverContacts: [Contact] = contacts.contacts
	
    @IBOutlet var searchBar: UISearchBar!

    @IBAction func starTapGestureRecognizer(sender: AnyObject) {
        //Determine the rowindex via the touch point 
        let tapPoint: CGPoint = sender.locationInView(self.tableView)
        let selectedIndex = self.tableView.indexPathForRowAtPoint(tapPoint)
		let contact = self.sections[selectedIndex!.section].contacts[selectedIndex!.row]

        contact.setFavorite(!contact.favorite, updateServer: true)
        self.tableView.reloadData()
    }
	
	func reloadContent(error_msg: String?) {
		if error_msg != nil {
			displayError(error_msg!, viewController: self)
		}
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
		
	
	// table sections
	var sections: [Section] {
		// return if already initialized
		/*if self._sections != nil {
			return self._sections!
		}*/
		
		// create empty sections
		var sections = [Section]()
		for _ in 0..<self.collation.sectionIndexTitles.count {
			sections.append(Section())
		}
		
		
		// put each currency in a section
		for contact in serverContacts {
			let section = self.collation.sectionForObject(contact, collationStringSelector: "resultingName")
			sections[section].addContact(contact)
		}
		
		// sort each section
		for section in sections {
			section.contacts = self.collation.sortedArrayFromArray(section.contacts, collationStringSelector: "resultingName") as! [Contact]
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
		//limits are not updated now
		
		contacts.updateContacts {(succeeded: Bool, error_msg: String?) -> () in
			if !succeeded {
				displayError(error_msg!, viewController: self)
			}
			self.reload()
			self.contactsRefreshControl.endRefreshing()
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		reload()
	}
	
	func reload() {
		//Filter contacts based on search query
		if searchBar.text == "" {
			serverContacts = contacts.contacts
		} else {
			let needle = searchBar.text
			serverContacts = contacts.contacts.filter{$0.resultingName.lowercaseString.rangeOfString(needle!.lowercaseString) != nil}
		}
		
		dispatch_async(dispatch_get_main_queue(), {
			//so it is run now, instead of at the end of code execution
			self.tableView.reloadData()
		})
		
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
			return self.collation.sectionTitles[section] 
		}
		return "" //Only works correct if table style is plain, otherwise height of the next section header will be too big
	}
	
	/* section index titles displayed to the right of the `UITableView` */
	override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String] {
		return self.collation.sectionIndexTitles
	}
	
	override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
		return self.collation.sectionForSectionIndexTitleAtIndex(index)
	}


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {


		if segue.identifier == "existing_contact" {
			//make sure that the segue is going to secondViewController
			let selectedIndex : NSIndexPath = self.tableView.indexPathForSelectedRow!
			let destVC = segue.destinationViewController as! ContactViewController
			destVC.contact = self.sections[selectedIndex.section].contacts[selectedIndex.row]
			destVC.delegate = self
		} else if segue.identifier == "new_contact" {
			let navigationController = segue.destinationViewController as! UINavigationController
			let destVC = navigationController.viewControllers[0] as! ContactViewController
			destVC.contact = Contact(name: "", friendlyName: "", registered: false, favorite: true, autoAccept: .Manual, identifiers: [], propagatedToServer: false)
			destVC.delegate = self
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
    
	func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
		// called when text changes (including clear)
		
        //println("search typed")
		reload()
    }
    
    func searchBarSearchButtonClicked( searchBar: UISearchBar!)
    {
        //println("searched")
	}
    

	func searchBarCancelButtonClicked( searchBar: UISearchBar!)
	{
		//To hide searchbar
		searchBar.text = ""
		searchBar.resignFirstResponder()
		
		self.tableView.setContentOffset(CGPointMake(0, searchBar.frame.size.height), animated: false)
		
		reload()
	}
}

class ContactCell: UITableViewCell {	
	@IBOutlet var nameLabel: UILabel!
    @IBOutlet var spinner: UIActivityIndicatorView!
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
	
	func markup(contact: Contact){
		if contact.favorite {
			statusImage.hidden = true
		} else {
			statusImage.hidden = false
		}
		
		if contact.propagatedToServer == false {
			spinner.hidden = false
			spinner.startAnimating()
		} else {
			spinner.hidden = true
		}
		
		nameLabel.text = contact.resultingName
	}
	
	
}


