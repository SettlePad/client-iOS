//
//  transactions.swift
//  UOless
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

import Foundation

class TransactionsController {
//extension APIController {
    var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
    var settingsDictionary: AnyObject? = nil
    
    var transactions = [Transaction]()
    var nr_of_results: String
    var search = ""
    var newest_id = 0
    var oldest_id = 0
    var last_update = 0
    var end_reached = false
    
    var active_task: NSURLSessionDataTask?
    var last_read: NSDate
    var api: APIController
    
    init(api: APIController) {
        self.api = api
        self.last_read = NSCalendar.currentCalendar().dateFromComponents(NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate()))! //TODO: replace by CoreData
        
        settingsDictionary = NSDictionary(contentsOfFile: documentList!)
        nr_of_results = String(settingsDictionary!["transactions_nr_of_results"]! as Int)
    }
    
    func clear() {
        transactions = []
    }
    
    func get(search: String, requestCompleted : (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> ()) {
        
        
        self.search = search.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
        var url = "transactions/initial/"+nr_of_results+"/"+self.search
        self.transactions = [] //already clear out before reponse
        self.end_reached = false
        getInternal(url){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
            self.transactions = [] //clear again to be sure
            if (succeeded) {
                if let transactions = dataDict!["transactions"] as? NSMutableArray {
                    self.updateParams(dataDict!) //Update request parameters
                    for transactionObj in transactions {
                        if let transactionDict = transactionObj as? NSDictionary {
                            var transaction = Transaction(fromDict: transactionDict)
                            self.transactions.append(transaction) //Add in rear
                        } else {
                            println("Cannot parse transaction as dictionary")
                        }
                    }
                } else {
                    //no transactions, which is fine
                }
            }
            if (self.transactions.count < self.settingsDictionary!["transactions_nr_of_results"]! as Int) {
                self.end_reached = true
            }
            requestCompleted(succeeded: succeeded,transactions: self.transactions,error_msg: error_msg)
        }
    }
    
    func getMore(requestCompleted : (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> ()) {
        var url = "transactions/older/\(oldest_id)/"+nr_of_results+"/"+search
        if (self.end_reached) {
            requestCompleted(succeeded: false,transactions: self.transactions,error_msg: "End reached")
        } else {
            getInternal(url){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
                if (succeeded) {
                    if let transactions = dataDict!["transactions"] as? NSMutableArray {
                        self.updateParams(dataDict!) //Update request parameters
                        for transactionObj in transactions {
                            if let transactionDict = transactionObj as? NSDictionary {
                                var transaction = Transaction(fromDict: transactionDict)
                                self.transactions.append(transaction) //Add in rear
                            } else {
                                println("Cannot parse transaction as dictionary")
                            }
                        }
                    } else {
                        //no transactions, which is fine
                        self.end_reached = true
                    }
                }
                requestCompleted(succeeded: succeeded,transactions: self.transactions,error_msg: error_msg)
            }
        }
    }
    
    func getUpdate(requestCompleted : (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> ()) {
        var url = "transactions/changes/\(oldest_id)/\(newest_id)/\(last_update)"+"/"+nr_of_results+"/"+search
        
        getInternal(url){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
            if (succeeded) {
                if let updatedTransactionsArray = dataDict!["updates"]!["transactions"] as? NSMutableArray {

                    //create dictionary of id (of transaction) to index (in array)
                    var transactionKeyDict = [Int:Int]()
                    for (i, transaction) in enumerate(self.transactions) {
                        transactionKeyDict[transaction.transaction_id!] = i //Can be unwrapped safely, as no draft transactions are created here
                    }

                    //Loop over updated transactions
                    for transactionObj in updatedTransactionsArray {
                        if let transactionDict = transactionObj as? NSDictionary {
                            var transaction = Transaction(fromDict: transactionDict)
                            if let indexInt = transactionKeyDict[transaction.transaction_id!] { //Can be unwrapped safely, as no draft transactions are created here
                                self.transactions[indexInt] = transaction //Replace
                            } else {
                                println("Cannot find transaction in local list")
                            }
                        }
                    }
                    
                    self.updateParams(dataDict!["updates"]! as NSDictionary) //Update request parameters
                }
                
                if let newerTransactionsArray = dataDict!["newer"]!["transactions"] as? NSMutableArray {
                    
                    //Loop over new transactions
                    for (i, transactionObj) in enumerate(newerTransactionsArray) {
                        //append
                        if let transactionDict = transactionObj as? NSDictionary {
                            var transaction = Transaction(fromDict: transactionDict)
                            self.transactions.insert(transaction,atIndex: i)
                        } else {
                            println("Cannot parse transaction as dictionary")
                        }
                    }
                    
                    self.updateParams(dataDict!["newer"]! as NSDictionary) //Update request parameters
                }
                
            }
            
            requestCompleted(succeeded: succeeded,transactions: self.transactions,error_msg: error_msg)
        }
    }
    
    private func getInternal(url: String, requestCompleted : (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> ()) {
        if (self.active_task != nil) {
            //cancel request
            requestCompleted(succeeded: false,dataDict: nil,error_msg: "Already performing a request")
        } else {
            self.active_task = api.request(url, method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                //println(data)
                if(succeeded) {
                    if let dataDict = data["data"] as? NSDictionary {
                        requestCompleted(succeeded: true,dataDict:dataDict,error_msg:nil)
                    } else {
                        //no transactions
                        requestCompleted(succeeded: true,dataDict:[:],error_msg:nil)

                    }
                } else {
                    if let error_msg = data["text"] as? String {
                        requestCompleted(succeeded: false,dataDict: nil, error_msg: error_msg)
                    } else {
                        requestCompleted(succeeded: false,dataDict: nil, error_msg: "Unknown error")
                    }
                }
              self.active_task = nil
            }
        }
    }
    
    private func updateParams(data: NSDictionary) {
        if let newest_id = data["newest_id"] as? Int {
            self.newest_id = max(newest_id,self.newest_id)
        }
        if let oldest_id = data["oldest_id"] as? Int {
            if (self.oldest_id == 0) {
                self.oldest_id = oldest_id
            } else {
                self.oldest_id = min(oldest_id,self.oldest_id)
            }
        }
        if let last_update = data["last_update"] as? Int {
            self.last_update = max(last_update,self.last_update)
        }
    }
    
    func getTransactions() -> [Transaction] {
        return transactions
    }
    
    func getTransaction(index: Int) -> Transaction? {
        if (index>=0 && index < transactions.count) {
            return transactions[index]
        } else {
            return nil
        }
    }
    
    func changeTransaction(action: String, transaction: Transaction, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
        var url = "transactions/"+action+"/\(transaction.transaction_id)/"
        api.request(url, method: "POST", formdata: [:], secure: true){ (succeeded: Bool, data: NSDictionary) -> () in
            if(succeeded) {
                requestCompleted(succeeded: true,error_msg: nil)
            } else {
                if let msg = data["text"] as? String {
                    requestCompleted(succeeded: false,error_msg: msg)
                } else {
                    requestCompleted(succeeded: false,error_msg: "Unknown")
                }
            }
        }
    }
}
