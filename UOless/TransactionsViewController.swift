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
*/

import UIKit

class TransactionsViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    var transactions: NSArray = []
    @IBOutlet var transactionsTableView: UITableView!

    var transactionAPI = TransactionsController(api: api)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        transactionAPI.get(""){ (succeeded: Bool, transactions: NSArray?, msg: String?) -> () in
            if (succeeded) {
                self.transactions = transactions!
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.transactionsTableView!.reloadData()
                })
                
                for transaction in transactions! { // loop through data items
                    println(transaction.description!)
                }
            } else {
                println("Error: "+msg!)
            }
        }
        
        transactionsTableView.tableFooterView = UIView(frame:CGRectZero) //To hide empty cells
        
        //To hide searchbar
        transactionsTableView.setContentOffset(CGPointMake(0, self.searchDisplayController!.searchBar.frame.size.height), animated: false)
        
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
        return transactions.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("TransactionCell", forIndexPath: indexPath) as TransactionsCell
        //Note that if self is left out, the app will crash when clicking on search bar

        // Configure the cell...
        if let transaction = transactions[indexPath.row] as? NSDictionary {
        //Description
            cell.descriptionLabel.text = (transaction["description"]! as String)
        
        //Amount
            var amountFloat = (transaction["amount"]! as Double)
            let floatFormat = ".2" //See http://www.codingunit.com/printf-format-specifiers-format-conversions-and-formatted-output
            cell.amountLabel.text = (transaction["currency"]! as String)+" \(amountFloat.format(floatFormat))"
            if (amountFloat < 0) {
                cell.amountLabel.textColor = UIColor(red: 0xbb/255, green: 0x00/255, blue: 0x05/255, alpha: 1.0) //Hex BB0005
            } else {
                cell.amountLabel.textColor = UIColor(red: 0x08/255, green: 0x99/255, blue: 0x00/255, alpha: 1.0) //Hex 089900
            }

        //Counterpart
            cell.counterpartLabel.text = (transaction["counterpart_name"]! as String)
        
        //Status (text and image)
            var statusInt = (transaction["status"]! as Int)
            // 0 = processed
            // 1 = recipient should accept first
            // 3 = cancelled/ rejected
        
            var reducedInt = (transaction["reduced"]! as Int)
            // 0 = not processed (yet)
            // 1 = processed
        
            var isSenderInt = (transaction["is_sender"]! as Int)
            // 0 = recipient
            // 1 = sender
        
            var statusString = "Unknown"
            if (statusInt == 0) {
                if (reducedInt == 0) {
                    statusString = ""
                } else {
                    statusString = ""
                }
                //cell.statusImageView.image = UIImage(named: "ios_new")
                cell.statusImageView.image = nil
            } else if (statusInt == 1) {
                if (isSenderInt == 0) {
                    statusString = "Waiting for approval from "+(transaction["counterpart_name"]! as String)
                } else {
                    statusString = "Requires your approval (swipe)"
                    //cell.counterpartLabel.textColor = UIColor(red: 0xff/255, green: 0x90/255, blue: 0x17/255, alpha: 1.0) //Hex ff9017, orange
                }
                cell.statusImageView.image = UIImage(named: "ios_attention")


                //all other labels in grey (Hex 777777)

            } else {
                //transaction canceled
                cell.statusImageView.image = nil

                if (isSenderInt == 0) {
                    statusString = "Rejected by "+(transaction["counterpart_name"]! as String)
                } else {
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
            var dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var timesentDate = dateFormatter.dateFromString((transaction["time_sent"]! as String))! //NSDate
        
            //See http://stackoverflow.com/questions/24577087/comparing-nsdates-without-time-component
            let today = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate()))
            let weekAgo = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate(timeIntervalSinceNow: -60*60*24*6)))
            
            var labeldateFormatter = NSDateFormatter()
            if (timesentDate.compare(today!) != NSComparisonResult.OrderedAscending) {
                //Today, display time
                //http://makeapppie.com/tag/date-to-string-in-swift/
                labeldateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                labeldateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
            } else if (timesentDate.compare(weekAgo!) != NSComparisonResult.OrderedAscending) {
                //Last seven days, display day of the week
                labeldateFormatter.dateFormat = "eeee" //http://zframework.ph/swift-ios-date-formatting-options/
            } else {
                //Longer than 7 days ago, display date
                labeldateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
                labeldateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
            }
            var dateString = labeldateFormatter.stringFromDate(timesentDate)
            if (isSenderInt == 0) {
                cell.timeLabel.text = "Received: "+dateString
            } else {
                cell.timeLabel.text = "Sent: "+dateString                
            }
        }
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
    
    //http://www.raywenderlich.com/76519/add-table-view-search-swift
    /*func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        transactionAPI.get(searchString){ (succeeded: Bool, transactions: NSArray?, msg: String?) -> () in
            if (succeeded) {
                self.transactions = transactions!
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.transactionsTableView!.reloadData()
                })
                
                for transaction in transactions! { // loop through data items
                    println(transaction.description!)
                }
            } else {
                println("Error: "+msg!)
            }
        }
        return true
    }*/
    
    /*func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        transactionAPI.get(self.searchDisplayController!.searchBar.text){ (succeeded: Bool, transactions: NSArray?, msg: String?) -> () in
            if (succeeded) {
                self.transactions = transactions!
                dispatch_async(dispatch_get_main_queue(), {
                    //so it is run now, instead of at the end of code execution
                    self.transactionsTableView!.reloadData()
                })
                
                for transaction in transactions! { // loop through data items
                    println(transaction.description!)
                }
            } else {
                println("Error: "+msg!)
            }
        }
        return true
    }*/

}