//
//  TransactionsViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

/* See
    http://www.raywenderlich.com/81879/storyboards-tutorial-swift-part-1
    http://www.johnmullins.co/blog/2014/08/06/swift-json/
    http://www.appcoda.com/pull-to-refresh-uitableview-empty/
    http://www.raywenderlich.com/73602/dynamic-table-view-cell-height-auto-layout
*/

import UIKit

class TransactionsViewController: UITableViewController {
    @IBAction func unwindToTransactions(segue: UIStoryboardSegue) {
    
    }
    
    @IBOutlet var transactionsTableView: UITableView!
    @IBOutlet var transactionsSearchBar: UISearchBar!
    
    var transactionAPI = TransactionsController(api: api)
    var transactionsRefreshControl:UIRefreshControl!
    var footer = footerView(frame: CGRectMake(0, 0, 320, 44))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        transactionAPI.clear()
        reload_transactions(loading: true) //want to show spinner
        
        transactionAPI.get(""){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                self.api_error(error_msg!)
            }
        }

        /*
        //To hide empty separators (not needed as footer is already implemented by reload_transactions()
        transactionsTableView.tableFooterView = UIView(frame:CGRectZero)
        transactionsTableView.tableFooterView = self.footer
        */

        //Set table background to specific color
        transactionsTableView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        //To hide searchbar
        transactionsTableView.setContentOffset(CGPointMake(0, transactionsSearchBar.frame.size.height), animated: false)
        
        //Add pull to refresh
            self.transactionsRefreshControl = UIRefreshControl()
            self.transactionsRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
            self.transactionsRefreshControl.addTarget(self, action: "refreshTransactions", forControlEvents: UIControlEvents.ValueChanged)
            self.transactionsTableView.addSubview(transactionsRefreshControl)
        
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
        return transactionAPI.getTransactions().count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = transactionsTableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as TransactionsCell
        
        // Configure the cell...
        if let transaction = transactionAPI.getTransaction(indexPath.row)  {
        
        //Description
            cell.descriptionLabel.text = transaction.description
            
        //Amount
            let floatFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
            cell.amountLabel.text = transaction.currency+" \(transaction.amount.format(floatFormat))"
            if (transaction.amount < 0) {
                cell.amountLabel.textColor = UIColor(red: 0xbb/255, green: 0x00/255, blue: 0x05/255, alpha: 1.0) //Hex BB0005
            } else {
                cell.amountLabel.textColor = UIColor(red: 0x08/255, green: 0x99/255, blue: 0x00/255, alpha: 1.0) //Hex 089900
            }

        //Counterpart
            cell.counterpartLabel.text = transaction.counterpart_name
            
        //Status (text and image)
            var statusString = "Unknown"
            if (transaction.status == 0) {
                //processed
                if (transaction.reduced == false) {
                    //not reduced (yet)
                    statusString = ""
                } else {
                    //reduced
                    statusString = ""
                }
                //cell.statusImageView.image = UIImage(named: "ios_new")
                cell.statusImageView.image = nil
            } else if (transaction.status == 1) { // 1 = recipient should accept first
                if (transaction.is_sender == true) { // 0 = recipient
                    statusString = "Pending approval"
                } else {
                    statusString = "Swipe to approve"
                    //cell.counterpartLabel.textColor = UIColor(red: 0xff/255, green: 0x90/255, blue: 0x17/255, alpha: 1.0) //Hex ff9017, orange
                }
                cell.statusImageView.image = UIImage(named: "ios_attention")


                //all other labels in grey (Hex 777777)

            } else { // 3 = cancelled/ rejected
                //transaction canceled
                cell.statusImageView.image = nil
                 if (transaction.is_sender == false) {
                    //recipient
                    statusString = "Rejected by "+transaction.counterpart_name
                } else {
                    //sender
                    statusString = "Rejected by you"
                }
                
                //all labels in grey (Hex 777777)
                cell.counterpartLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
                cell.amountLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
                cell.descriptionLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
                cell.statusLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
                cell.timeLabel.textColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)

                
                //all labels strikethrough
                var attributedcounterpartText = NSMutableAttributedString(string: cell.counterpartLabel.text!)
                attributedcounterpartText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedcounterpartText.length))
                cell.counterpartLabel.attributedText = attributedcounterpartText
                
                var attributedamountText = NSMutableAttributedString(string: cell.amountLabel.text!)
                attributedamountText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedamountText.length))
                cell.amountLabel.attributedText = attributedamountText
                
                var attributeddescriptionText = NSMutableAttributedString(string: cell.descriptionLabel.text!)
                attributeddescriptionText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributeddescriptionText.length))
                cell.descriptionLabel.attributedText = attributeddescriptionText
                
                var attributedstatusText = NSMutableAttributedString(string: cell.statusLabel.text!)
                attributedstatusText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedstatusText.length))
                cell.statusLabel.attributedText = attributedcounterpartText
                
                var attributedtimeText = NSMutableAttributedString(string: cell.timeLabel.text!)
                attributedtimeText.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributedtimeText.length))
                cell.timeLabel.attributedText = attributedtimeText
            }

        
            cell.statusLabel.text = statusString

        //Time
            //See http://stackoverflow.com/questions/24577087/comparing-nsdates-without-time-component
            let today = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate()))
            let weekAgo = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate(timeIntervalSinceNow: -60*60*24*6)))
            
            var labeldateFormatter = NSDateFormatter()
            if (transaction.time_sent.compare(today!) != NSComparisonResult.OrderedAscending) {
                //Today, display time
                //http://makeapppie.com/tag/date-to-string-in-swift/
                labeldateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                labeldateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
            } else if (transaction.time_sent.compare(weekAgo!) != NSComparisonResult.OrderedAscending) {
                //Last seven days, display day of the week
                labeldateFormatter.dateFormat = "eeee" //http://zframework.ph/swift-ios-date-formatting-options/
            } else {
                //Longer than 7 days ago, display date
                labeldateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
                labeldateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
            }
            var dateString = labeldateFormatter.stringFromDate(transaction.time_sent)
            if (transaction.is_sender == false) {
                cell.timeLabel.text = "Received: "+dateString
            } else {
                cell.timeLabel.text = "Sent: "+dateString                
            }
            

        }
        

        
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        //Editable or not
        if let transaction = transactionAPI.getTransaction(indexPath.row)  {
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
        if let transaction = transactionAPI.getTransaction(indexPath.row)  {
            if transaction.can_be_canceled {
                var cancelAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Cancel" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                        self.changeTransaction("cancel", transaction: transaction)
                })
                cancelAction.backgroundColor = UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0) //#777777
                return [cancelAction]

            } else if transaction.can_be_accepted {
                //mutually exclusive with can_be_canceled, which can happen if user is sender. This can only happen if user is recipient
                var acceptAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Accept" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                    self.changeTransaction("accept", transaction: transaction)
                })
                acceptAction.backgroundColor = UIColor(red: 0x08/255, green: 0x99/255, blue: 0x00/255, alpha: 1.0) //#089900
                
                var rejectAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Reject" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
                    self.changeTransaction("reject", transaction: transaction)
                })
                rejectAction.backgroundColor = UIColor(red: 0xbb/255, green: 0x00/255, blue: 0x05/255, alpha: 1.0) //#bb0005
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
        self.transactionAPI.changeTransaction(action,transaction: transaction) { (succeeded: Bool, error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.refreshTransactions()
                })
            } else {
                self.api_error(error_msg!)
            }
            self.transactionsRefreshControl.endRefreshing()
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
        transactionAPI.clear()
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
        transactionAPI.get(searchBar.text){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                self.api_error(error_msg!)
            }
        }
        
        reload_transactions(loading: true) //want to show spinner
    }
    
    func searchBarCancelButtonClicked( searchBar: UISearchBar!)
    {
        //To hide searchbar
        searchBar.text = ""
        searchBar.resignFirstResponder()
        let y = self.tableView!.contentOffset.y + searchBar!.frame.height
        let newContentOffset = CGPoint(x:0, y: y)
        self.transactionsTableView.setContentOffset(newContentOffset, animated: true)
        //self.transactionsTableView.scrollRectToVisible(CGRectMake(0, 44,0,0), animated: true)
        
        transactionAPI.get(""){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                self.api_error(error_msg!)
            }
        }
        
        reload_transactions(loading: true) //want to show spinner
    }
    
    func refreshTransactions() {        
        transactionAPI.getUpdate(){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
            if (succeeded) {
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.reload_transactions()
                })
            } else {
                self.api_error(error_msg!)
            }
            self.transactionsRefreshControl.endRefreshing()
        }
    }
    
    @IBAction func viewTapped(sender : AnyObject) {
        //To hide the keyboard, when needed
        self.view.endEditing(true)
    }
    
    //To do infinite scrolling
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        //println("scroll")

        if (!transactionAPI.end_reached && transactionAPI.active_task == nil) {
            let currentOffset = scrollView.contentOffset.y
            let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
            
            if (maximumOffset - currentOffset) <= 40 {
                transactionAPI.getMore(){ (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> () in
                    if (succeeded) {
                        dispatch_async(dispatch_get_main_queue(), {
                            //so it is run now, instead of at the end of code execution
                            self.reload_transactions()
                        })
                    } else {
                        self.api_error(error_msg!)
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
            self.footer.end_reached = self.transactionAPI.end_reached
        }
        self.footer.no_results = (self.transactionAPI.getTransactions().count == 0)
        self.footer.setNeedsDisplay()
        self.transactionsTableView.tableFooterView = self.footer
    }
    
    private func api_error(msg: String) {
        println("Error: "+msg)
        
        //Goto login screen
        if (!api.is_loggedIn()) {
            dispatch_async(dispatch_get_main_queue()) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("LoginController") as UIViewController
                self.presentViewController(vc, animated: false, completion: nil)
            }
        } else {
            //TODO: in future, display error
            /* 
            var alert = UIAlertView(title: "Success!", message: msg, delegate: nil, cancelButtonTitle: "Okay.")
            alert.title = "Error"
            alert.message = msg
            
            // Move to the UI thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Show the alert
                alert.show()
            }) 
            */
            
        }
    }
}