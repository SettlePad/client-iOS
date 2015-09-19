//
//  CurrenciesViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 08/01/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

// See http://www.pumpmybicep.com/2014/07/04/uitableview-sectioning-and-indexing/

import UIKit

class CurrenciesViewController: UITableViewController {
    @IBOutlet var currenciesTableView: UITableView!
    
    var selectedIndexPath: NSIndexPath?

	
	class CurrencyObject: NSObject {
		let longName: String
		let abbrev: String
		let currency: Currency
		
		init(abbrev: String, longName: String, currency: Currency) {
			self.abbrev = abbrev
			self.longName = longName
			self.currency = currency
		}
	}
	
    // custom type to represent table sections
    class Section {
        var currencies: [CurrencyObject] = []
		
        func addCurrency(currency: CurrencyObject) {
            self.currencies.append(currency)
        }
    }
    
    // `UIKit` convenience class for sectioning a table
    let collation = UILocalizedIndexedCollation.currentCollation()
        
    
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
        for currency in Currency.allValues {
			let currencyObject = CurrencyObject(abbrev: currency.rawValue, longName: currency.toLongName(), currency: currency)
			
			let section = self.collation.sectionForObject(currencyObject, collationStringSelector: "longName")
            sections[section].addCurrency(currencyObject)
        }
        
        // sort each section
        for section in sections {
			 section.currencies = self.collation.sortedArrayFromArray(section.currencies, collationStringSelector: "longName") as! [CurrencyObject]
        }
                
        self._sections = sections
        
        return self._sections!
    }
    var _sections: [Section]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        //Move to selected currency
        for (sectionindex, section) in sections.enumerate() {
            for (rowindex, currencyObject) in section.currencies.enumerate() {
                if currencyObject.currency == user?.defaultCurrency {
                    selectedIndexPath = NSIndexPath(forRow:rowindex, inSection:sectionindex)
                }
            }
        }

        
        if selectedIndexPath != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.currenciesTableView.scrollToRowAtIndexPath(self.selectedIndexPath!, atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            })
        }
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return self.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return self.sections[section].currencies.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CurrencyCell", forIndexPath: indexPath) 
        
        // Configure the cell...
        let currencyObject = self.sections[indexPath.section].currencies[indexPath.row]
        cell.textLabel?.text = currencyObject.longName

        //Determine whether the selected index path
        if currencyObject.currency == user?.defaultCurrency {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    /* section headers appear above each `UITableView` section */
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
            // do not display empty `Section`s
            if !self.sections[section].currencies.isEmpty {
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Other row is selected - need to deselect it
        if let index = selectedIndexPath {
            let cell = tableView.cellForRowAtIndexPath(index)
            cell?.accessoryType = .None
        }
        
        //Update currency
        selectedIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let currencyObject = self.sections[indexPath.section].currencies[indexPath.row]

        user?.defaultCurrency = currencyObject.currency
        cell?.accessoryType = .Checkmark
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
