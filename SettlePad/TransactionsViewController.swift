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

class TransactionsViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, NewUOmeModalDelegate {	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showUOmeSegueFromTransactions" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let vc = navigationController.viewControllers[0] as! NewUOmeViewController
            vc.delegate = self
        }
    }
    
    func transactionsPosted(controller:NewUOmeViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        self.refreshTable()
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
				self.refreshTransactions()
			}
		} else {
			self.refreshTransactions()
		}
    }
	
    @IBOutlet var transactionsTableView: UITableView!
    @IBOutlet var transactionsSearchBar: UISearchBar!
	
    @IBOutlet var transationsGroupSegmentedControl: UISegmentedControl!
    
    var transactionsRefreshControl:UIRefreshControl!
    var footer = TransactionsFooterView(frame: CGRectMake(0, 0, 320, 44))
 
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        activeUser!.transactions.clear()
        refreshTable(true) //want to show spinner
        
		activeUser!.transactions.get(.Open, search: "",
			success: {
				dispatch_async(dispatch_get_main_queue(), {
					//so it is run now, instead of at the end of code execution
					self.refreshTable()
				})
			},
			failure: {error in
				displayError(error.errorText, viewController: self)
			}
		)

        /*
        //To hide empty separators (not needed as footer is already implemented by refreshTable()
        transactionsTableView.tableFooterView = UIView(frame:CGRectZero)
        transactionsTableView.tableFooterView = self.footer
        */

        //Set table background to specific color
        //transactionsTableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
		
        
        //Add pull to refresh
            self.transactionsRefreshControl = UIRefreshControl()
            self.transactionsRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
            self.transactionsRefreshControl.addTarget(self, action: "refreshTransactions", forControlEvents: UIControlEvents.ValueChanged)
            self.transactionsTableView.addSubview(transactionsRefreshControl)
        
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//Set cell height to dynamic. Note that it also requires a cell.layoutIfNeeded in cellForRowAtIndexPath!
		transactionsTableView.rowHeight = UITableViewAutomaticDimension
		transactionsTableView.estimatedRowHeight = 40
		
		//To hide searchbar
		transactionsTableView.setContentOffset(CGPointMake(0, transactionsSearchBar.frame.size.height), animated: false)
		
		
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return activeUser!.transactions.getTransactions().count
    }

    
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = transactionsTableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as! TransactionsCell
        
        // Configure the cell...
        if let transaction = activeUser!.transactions.getTransaction(indexPath.row)  {
            cell.markup(transaction)
        }
		cell.layoutIfNeeded() //to get right layout given dynamic height
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        //Editable or not
        if let transaction = activeUser!.transactions.getTransaction(indexPath.row)  {
            if (transaction.canBeCanceled || transaction.canBeAccepted) {
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
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        /*if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } */   
    }
    
    
	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?  {
        if let transaction = activeUser!.transactions.getTransaction(indexPath.row)  {
            if transaction.canBeCanceled {
                let cancelAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Cancel" , handler: { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                        self.changeTransaction("cancel", transaction: transaction)
                })
                cancelAction.backgroundColor = Colors.gray.textToUIColor()
                return [cancelAction]

            } else if transaction.canBeAccepted {
                //mutually exclusive with canBeCanceled, which can happen if user is sender. This can only happen if user is recipient
                let acceptAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Accept" , handler: { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                    self.changeTransaction("accept", transaction: transaction)
                })
                acceptAction.backgroundColor = Colors.success.textToUIColor()
                
                let rejectAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Reject" , handler: { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                    self.changeTransaction("reject", transaction: transaction)
                })
                rejectAction.backgroundColor = Colors.danger.backgroundToUIColor()
                return [acceptAction,rejectAction]
            } else {
                return nil
            }
        } else {
            print("not set?")
            return []
        }
    }
	
    func changeTransaction(action:String, transaction:Transaction){
        activeUser!.transactions.changeTransaction(action,transaction: transaction,
			success: {
				dispatch_async(dispatch_get_main_queue(), {
					self.refreshTransactions()
				})
			},
			failure: {error in
                displayError(error.errorText, viewController: self)
			}
		)
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
        activeUser!.transactions.clear()
        refreshTable(searching: true) //want to show search instructions
        
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
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar!)
    {
        //get new results
        newRequest()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar!)
    {
        //To hide searchbar
        searchBar.text = ""
        searchBar.resignFirstResponder()
		
		self.transactionsTableView.setContentOffset(CGPointMake(0, transactionsSearchBar.frame.size.height), animated: false)
		
        newRequest()
    }
	
	func newRequest() {
		var searchVal = ""
		if transactionsSearchBar.text != nil {
			searchVal = transactionsSearchBar.text!
		}

		activeUser!.transactions.get(getGroupType(),search: searchVal,
			success: {
				dispatch_async(dispatch_get_main_queue(), {
					//so it is run now, instead of at the end of code execution
					self.refreshTable()
				})
			},
			failure: {error in
				displayError(error.errorText, viewController: self)

			}
		)
		
		refreshTable(true) //want to show spinner
	}
	
    func refreshTransactions() {
        activeUser!.transactions.getUpdate(
			{
				dispatch_async(dispatch_get_main_queue(), {
					//so it is run now, instead of at the end of code execution
					self.refreshTable()
				})
			},
			failure: {error in
				displayError(error.errorText, viewController: self)

			}
		)
    }
    
    @IBAction func transactionsGroupValueChanged(sender: UISegmentedControl) {
		newRequest()
    }
	
	func getGroupType() -> TransactionsStatusGroup {
		if transationsGroupSegmentedControl.selectedSegmentIndex == 0 {
			return .Open
		} else if transationsGroupSegmentedControl.selectedSegmentIndex == 1 {
			return .Processed
		} else if transationsGroupSegmentedControl.selectedSegmentIndex == 2 {
			return .Canceled
		} else {
			return .All
		}
			
	}
	
    @IBAction func viewTapped(sender : AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
    }
    
    //To do infinite scrolling
	func scrollViewDidScroll(scrollView: UIScrollView) {
        //println("scroll")

        if (!activeUser!.transactions.endReached) {
            let currentOffset = scrollView.contentOffset.y
            let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
            
            if (maximumOffset - currentOffset) <= 40 {
                activeUser!.transactions.getMore(
					{
						dispatch_async(dispatch_get_main_queue(), {
							//so it is run now, instead of at the end of code execution
							self.refreshTable()
						})
					},
					failure: {error in
						displayError(error.errorText, viewController: self)
					}
				)
            }
        }
    }
    
    private func refreshTable(loading: Bool = false, searching: Bool = false) {
        self.transactionsTableView!.reloadData()

        /*for transaction in transactions! { // loop through data items
        println(transaction.description!)
        }*/
        
        self.footer.searching = searching
        if loading {
            self.footer.endReached = false
        } else {
            self.footer.endReached = activeUser!.transactions.endReached
        }
        self.footer.no_results = (activeUser!.transactions.getTransactions().count == 0)
        self.footer.setNeedsDisplay()
        self.transactionsTableView.tableFooterView = self.footer
		if loading == false {
			transactionsRefreshControl.endRefreshing()
		}
    }
}

class TransactionsFooterView: UIView {
	var endReached = true
	var no_results = true
	var searching = false
	
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
		
		
		if self.endReached || self.searching {
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