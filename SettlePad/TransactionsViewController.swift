//
//  TransactionsViewController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

/* See
    http://www.raywenderlich.com/81879/storyboards-tutorial-swift-part-1
    http://www.johnmullins.co/blog/2014/08/06/swift-json/
    http://www.appcoda.com/pull-to-refresh-uitableview-empty/
    http://www.raywenderlich.com/73602/dynamic-table-view-cell-height-auto-layout
*/

import UIKit

class TransactionsViewController: UITableViewController, NewUOmeModalDelegate {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showUOmeSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let vc = navigationController.viewControllers[0] as! NewUOmeViewController
            vc.delegate = self
        }
    }
    
    func transactionsPosted(controller:NewUOmeViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        self.reload_transactions()
    }
    
	func transactionsPostCompleted(controller:NewUOmeViewController, error_msg: String?) {
		//Goto login screen
		if error_msg != nil {
			displayError(error_msg!, self)
			if (user == nil) {
				dispatch_async(dispatch_get_main_queue()) {
					let storyboard = UIStoryboard(name: "Main", bundle: nil)
					let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") as! UIViewController
					self.presentViewController(vc, animated: false, completion: nil)
				}
			} else {
				self.refreshTransactions()
			}
		} else {
			self.refreshTransactions()
		}
    }
	
    @IBOutlet var transactionsTableView: UITableView!
    @IBOutlet var transactionsSearchBar: UISearchBar!
	
    var transactionsRefreshControl:UIRefreshControl!
    var footer = TransactionsFooterView(frame: CGRectMake(0, 0, 320, 44))
 
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        transactions.clear()
        reload_transactions(loading: true) //want to show spinner
        
        transactions.get(""){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.reload_transactions()
			})
			if (!succeeded) {
                displayError(error_msg!, self)
            }
        }

        /*
        //To hide empty separators (not needed as footer is already implemented by reload_transactions()
        transactionsTableView.tableFooterView = UIView(frame:CGRectZero)
        transactionsTableView.tableFooterView = self.footer
        */

        //Set table background to specific color
        //transactionsTableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        //To hide searchbar
        transactionsTableView.setContentOffset(CGPointMake(0, transactionsSearchBar.frame.size.height), animated: false)
        
        //Add pull to refresh
            self.transactionsRefreshControl = UIRefreshControl()
            self.transactionsRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
            self.transactionsRefreshControl.addTarget(self, action: "refreshTransactions", forControlEvents: UIControlEvents.ValueChanged)
            self.transactionsTableView.addSubview(transactionsRefreshControl)
        
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//Set cell height to dynamic
		transactionsTableView.rowHeight = UITableViewAutomaticDimension
		transactionsTableView.estimatedRowHeight = 40
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return transactions.getTransactions().count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = transactionsTableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as! TransactionsCell
        
        // Configure the cell...
        if let transaction = transactions.getTransaction(indexPath.row)  {
            cell.markup(transaction)
        }
        
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        //Editable or not
        if let transaction = transactions.getTransaction(indexPath.row)  {
            if (transaction.can_be_canceled || transaction.can_be_accepted) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
        
        //return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        /*if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } */   
    }
    
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        if let transaction = transactions.getTransaction(indexPath.row)  {
            if transaction.can_be_canceled {
                var cancelAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Cancel" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                        self.changeTransaction("cancel", transaction: transaction)
                })
                cancelAction.backgroundColor = Colors.gray.textToUIColor()
                return [cancelAction]

            } else if transaction.can_be_accepted {
                //mutually exclusive with can_be_canceled, which can happen if user is sender. This can only happen if user is recipient
                var acceptAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Accept" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                    self.changeTransaction("accept", transaction: transaction)
                })
                acceptAction.backgroundColor = Colors.success.textToUIColor()
                
                var rejectAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Reject" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                    self.changeTransaction("reject", transaction: transaction)
                })
                rejectAction.backgroundColor = Colors.danger.backgroundToUIColor()
                return [acceptAction,rejectAction]
            } else {
                return nil
            }
        } else {
            println("not set?")
            return []
        }
    }
    
    func changeTransaction(action:String, transaction:Transaction){
        transactions.changeTransaction(action,transaction: transaction) { (succeeded: Bool, error_msg: String?) -> () in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.refreshTransactions()
			})
			if (!succeeded) {
                displayError(error_msg!, self)
            }
        }
    }

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
    
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool // return NO to not become first responder
    {
        transactions.clear()
        reload_transactions(searching: true) //want to show search instructions
        
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
        //println("search typed")
    }
    
    func searchBarSearchButtonClicked( searchBar: UISearchBar!)
    {
        //println("searched")
        
        //get new results
        transactions.get(searchBar.text){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.reload_transactions()
			})
			if (!succeeded) {
                displayError(error_msg!, self)
            }
        }
        
        reload_transactions(loading: true) //want to show spinner
    }
    
    func searchBarCancelButtonClicked( searchBar: UISearchBar!)
    {
        //To hide searchbar
        searchBar.text = ""
        searchBar.resignFirstResponder()
		
		self.transactionsTableView.setContentOffset(CGPointMake(0, transactionsSearchBar.frame.size.height), animated: false)
        
        transactions.get(""){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.reload_transactions()
			})
			if (!succeeded) {
                displayError(error_msg!, self)
            }
        }
        
        reload_transactions(loading: true) //want to show spinner
    }
    
    func refreshTransactions() {        
        transactions.getUpdate(){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
			dispatch_async(dispatch_get_main_queue(), {
				//so it is run now, instead of at the end of code execution
				self.reload_transactions()
			})
			if (!succeeded) {
                displayError(error_msg!, self)
            }

        }
    }
    
    @IBAction func viewTapped(sender : AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
    }
    
    //To do infinite scrolling
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        //println("scroll")

        if (!transactions.end_reached) {
            let currentOffset = scrollView.contentOffset.y
            let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
            
            if (maximumOffset - currentOffset) <= 40 {
                transactions.getMore(){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
					dispatch_async(dispatch_get_main_queue(), {
						//so it is run now, instead of at the end of code execution
						self.reload_transactions()
					})
					if (!succeeded && error_msg! != "") {
						displayError(error_msg!, self)
                    }
                }
            }
        }
    }
    
    private func reload_transactions(loading: Bool = false, searching: Bool = false) {
        self.transactionsTableView!.reloadData()

        /*for transaction in transactions! { // loop through data items
        println(transaction.description!)
        }*/
        
        self.footer.searching = searching
        if loading {
            self.footer.end_reached = false
        } else {
            self.footer.end_reached = transactions.end_reached
        }
        self.footer.no_results = (transactions.getTransactions().count == 0)
        self.footer.setNeedsDisplay()
        self.transactionsTableView.tableFooterView = self.footer
		if loading == false {
			transactionsRefreshControl.endRefreshing()
		}
    }
}

class TransactionsFooterView: UIView {
	var end_reached = true
	var no_results = true
	var searching = false
	
	override init (frame : CGRect) {
		super.init(frame : frame)
		self.opaque = false //Required for transparent background
	}
	
	/*convenience override init () {
	self.init(frame:CGRectMake(0, 0, 320, 44)) //By default, make a rect of 320x44
	}*/
	
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	
	override func drawRect(rect: CGRect) {
		//To make sure we are not adding one layer of text onto another
		for view in self.subviews {
			view.removeFromSuperview()
		}
		
		
		if self.end_reached || self.searching {
			let footerLabel: UILabel = UILabel(frame: rect)
			footerLabel.textColor = Colors.gray.textToUIColor()
			footerLabel.font = UIFont.boldSystemFontOfSize(11)
			footerLabel.textAlignment = NSTextAlignment.Center
			
			if self.searching {
				footerLabel.text = "Press search after entering your query"
			} else if self.no_results {
				footerLabel.text = "No transactions"
			} else {
				footerLabel.text = "No more transactions"
			}
			self.addSubview(footerLabel)
		} else {
			let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
			spinner.startAnimating()
			spinner.frame = rect
			self.addSubview(spinner)
		}
	}
}