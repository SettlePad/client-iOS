//
//  transactions.swift
//  SettlePad
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation

class Transactions {
    var transactions = [Transaction]()
    var nr_of_results = 20
    var search = ""
    var newestID = 0
    var oldestID = 0
    var lastUpdate = 0
    var end_reached = false
    
    var lastRequest = NSDate(timeIntervalSinceNow: -24*60*60) //Only newer requests for getInternal will be succesfully completed. By default somewhere in the past (now one day)
	var blockingRequestActive = false
	
    init() {

    }
    
    func clear() {
        transactions = []
        nr_of_results = 20
        search = ""
        newestID = 0
        oldestID = 0
        lastUpdate = 0
        end_reached = false
    }
    
    func post(newTransactions: [Transaction], requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
        //Add to list with Posted status
        var formdataArray : [[String:AnyObject]] = []
        for newTransaction in newTransactions {
            newTransaction.status = .Posted
			formdataArray.append([
				"recipient":newTransaction.identifierStr,
				"description":newTransaction.description,
				"amount":newTransaction.amount,
				"currency":newTransaction.currency.rawValue
			])
        }
		
		if (formdataArray.count > 0) {
			transactions.insertContentsOf(newTransactions, at: 0)
			
			//Do post. When returned succesfully, replace status with what comes back
			let url = "memo/send/"
			api.request(url, method: "POST", formdata: formdataArray, secure: true){ (succeeded: Bool, data: NSDictionary) -> () in
				if(succeeded) {
					requestCompleted(succeeded: true,error_msg: nil)
					self.transactions = self.transactions.filter({$0.status != .Posted}) //Delete all 
					balances.updateBalances{(succeeded: Bool, error_msg: String?) -> () in }
				} else {
					if let msg = data["text"] as? String {
						requestCompleted(succeeded: false,error_msg: msg)
					} else {
						requestCompleted(succeeded: false,error_msg: "Unknown")
					}
				}
			}
		} else {
			requestCompleted(succeeded: false,error_msg: "No viable transactions")			
		}
        //At this point, the transactions array does not contain the new UOme's yet and should be refreshed. We leave this to the view controller (which is triggered by the requestCompleted above)
    }
    
    func get(search: String, requestCompleted : (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> ()) {
        
        
        self.search = search.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
        let url = "transactions/initial/"+String(nr_of_results)+"/"+self.search
        self.transactions = [] //already clear out before reponse
        self.end_reached = false
        getInternal(url, oneAtATime: true){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
            self.transactions = [] //clear again to be sure
            if (succeeded) {
                if let transactions = dataDict!["transactions"] as? NSMutableArray {
                    self.updateParams(dataDict!) //Update request parameters
                    for transactionObj in transactions {
                        if let transactionDict = transactionObj as? NSDictionary {
                            let transaction = Transaction(fromDict: transactionDict)
                            self.transactions.append(transaction) //Add in rear
                        } else {
                            print("Cannot parse transaction as dictionary")
                        }
                    }
                } else {
                    //no transactions, which is fine
                }
            }
            if (self.transactions.count < self.nr_of_results) {
                self.end_reached = true
            }
            requestCompleted(succeeded: succeeded,transactions: self.transactions,error_msg: error_msg)
        }
    }
    
    func getMore(requestCompleted : (succeeded: Bool, transactions: [Transaction], error_msg: String?) -> ()) {
        let url = "transactions/older/\(oldestID)/"+String(nr_of_results)+"/"+search
        if self.end_reached {
            requestCompleted(succeeded: false,transactions: self.transactions,error_msg: "End reached")
        } else if  transactions.count  == 0 {
            //No transactions yet, so ignore request
        } else {
            getInternal(url, oneAtATime: true){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
                if (succeeded) {
                    if let transactions = dataDict!["transactions"] as? NSMutableArray {
                        self.updateParams(dataDict!) //Update request parameters
                        for transactionObj in transactions {
                            if let transactionDict = transactionObj as? NSDictionary {
                                let transaction = Transaction(fromDict: transactionDict)
                                self.transactions.append(transaction) //Add in rear
								//TODO: add bool that checks whether we are already receiving something, otherwise we'll get the same response multiple times
                            } else {
                                print("Cannot parse transaction as dictionary")
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
        let url = "transactions/changes/\(oldestID)/\(newestID)/\(lastUpdate)"+"/"+String(nr_of_results)+"/"+search
		
        getInternal(url, oneAtATime: true){ (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> () in
            if (succeeded) {
                if let updatedTransactionsArray = dataDict!["updates"]!["transactions"] as? NSMutableArray {

                    //create dictionary of id (of transaction) to index (in array)
                    var transactionKeyDict = [Int:Int]()
                    for (i, transaction) in self.transactions.enumerate() {
                        transactionKeyDict[transaction.transaction_id!] = i //Can be unwrapped safely, as no draft transactions are created here
                    }

                    //Loop over updated transactions
                    for transactionObj in updatedTransactionsArray {
                        if let transactionDict = transactionObj as? NSDictionary {
                            let transaction = Transaction(fromDict: transactionDict)
                            if let indexInt = transactionKeyDict[transaction.transaction_id!] { //Can be unwrapped safely, as no draft transactions are created here
                                self.transactions[indexInt] = transaction //Replace
                            } else {
                                print("Cannot find transaction in local list")
                            }
                        }
                    }
                    
                    self.updateParams(dataDict!["updates"]! as! NSDictionary) //Update request parameters
                }
                
                if let newerTransactionsArray = dataDict!["newer"]!["transactions"] as? NSMutableArray {
                    
                    //Loop over new transactions
                    for (i, transactionObj) in newerTransactionsArray.enumerate() {
                        //append
                        if let transactionDict = transactionObj as? NSDictionary {
                            let transaction = Transaction(fromDict: transactionDict)
                            self.transactions.insert(transaction,atIndex: i)
                        } else {
                            print("Cannot parse transaction as dictionary")
                        }
                    }
                    
                    self.updateParams(dataDict!["newer"]! as! NSDictionary) //Update request parameters
                }
                
            }
            
            requestCompleted(succeeded: succeeded,transactions: self.transactions,error_msg: error_msg)
        }
    }
    
	private func getInternal(url: String, oneAtATime: Bool, requestCompleted : (succeeded: Bool, dataDict: NSDictionary?, error_msg: String?) -> ()) {
        let requestDate = NSDate()
        //println("Transaction request: "+url)
		if oneAtATime && blockingRequestActive {
			requestCompleted(succeeded: false,dataDict: nil, error_msg: "") //another blocking request is already pending
		} else {
			if oneAtATime {
				self.blockingRequestActive = true
			}
			api.request(url, method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            //println(data)
				if (requestDate.compare(self.lastRequest) != NSComparisonResult.OrderedAscending) { //requestDate is later than or equal to lastRequest
					if(succeeded) {
						self.lastRequest = requestDate
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
				} else {
					requestCompleted(succeeded: false,dataDict: nil, error_msg: "") //outdated request
				}
				if oneAtATime {
					self.blockingRequestActive = false
				}
			}
		}
    }
    
    private func updateParams(data: NSDictionary) {
        if let newestID = data["newest_id"] as? Int {
            self.newestID = max(newestID,self.newestID)
        }
        if let oldestID = data["oldest_id"] as? Int {
            if (self.oldestID == 0) {
                self.oldestID = oldestID
            } else {
                self.oldestID = min(oldestID,self.oldestID)
            }
        }
        if let lastUpdate = data["last_update"] as? Int {
            self.lastUpdate = max(lastUpdate,self.lastUpdate)
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
        let url = "transactions/"+action+"/\(transaction.transaction_id!)/"
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
