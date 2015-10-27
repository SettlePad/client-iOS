//
//  transactions.swift
//  SettlePad
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import SwiftyJSON

class Transactions {
	var countUnreadOpen: Int = 0
	var countUnreadCanceled: Int = 0
	var countUnreadProcessed: Int = 0
	var countOpen: Int = 0
	
    var transactions = [Transaction]()
    private var nr_of_results = 20
    private var search = ""
	private var group: TransactionsStatusGroup = .Open
    private var newestID = 0
    private var oldestID = 0
    private var lastUpdate = 0
    var end_reached = false
	
	var tabBarDelegate:TabBarDelegate?
	
    var lastRequest = NSDate(timeIntervalSinceNow: -24*60*60) //Only newer requests for getInternal will be succesfully completed. By default somewhere in the past (now one day)
	var blockingRequestActive = false
	
    init() {

    }
    
    func clear() {
        transactions = []
        nr_of_results = 20
        search = ""
		group = .Open
        newestID = 0
        oldestID = 0
        lastUpdate = 0
        end_reached = false
    }
    
	func post(newTransactions: [Transaction], success: ()->(), failure: (error: SettlePadError)->()) {
        //Add to list with Posted status
        var formdataArray : [[String:AnyObject]] = []
        for newTransaction in newTransactions {
            newTransaction.status = .Posted
			formdataArray.append([
				"recipient":newTransaction.usedIdentifierStr,
				"description":newTransaction.description,
				"amount":newTransaction.amount,
				"currency":newTransaction.currency.rawValue
			])
        }
		
		if (formdataArray.count > 0) {
			transactions.insertContentsOf(newTransactions, at: 0)
			
			//Do post. When returned succesfully, replace status with what comes back
			HTTPWrapper.request( "memo/send/", method: .POST, parameters: ["transactions": formdataArray], authenticateWithUser: activeUser!,
				success: {json in
					self.transactions = self.transactions.filter({$0.status != .Posted}) //Delete all
					balances.updateBalances({},failure: {_ in })
					success()
				},
				failure: { error in
					failure(error: error)
				}
			)
		} else {
			failure(error: SettlePadError(errorCode: "no_viable_transactions", errorText:"No viable transactions"))
		}
        //At this point, the transactions array does not contain the new UOme's yet and should be refreshed. We leave this to the view controller (which is triggered by the requestCompleted above)
    }
    
	func get(group: TransactionsStatusGroup, search: String, success: ()->(), failure: (error: SettlePadError)->()) {
        self.group = group
        self.search = search.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
        let url = "transactions/initial/"+String(nr_of_results)+"/"+self.group.rawValue+"/"+self.search
        self.transactions = [] //already clear out before reponse
        self.end_reached = false
        getInternal(url, oneAtATime: true,
			success: {json in
				self.updateParams(json["data"]) //Update request parameters
				for (_,subJson):(String, JSON) in json["data"]["transactions"] {
					self.transactions.append(Transaction(json: subJson)) //Add in rear
				}
				if (self.transactions.count < self.nr_of_results) {
					self.end_reached = true
				}
				success()
			},
			failure: {error in
				failure(error: error)
			}
		)
    }
    
	func getMore(success: () -> (), failure: (error: SettlePadError) -> ()) {
        let url = "transactions/older/\(oldestID)/"+String(nr_of_results)+"/"+self.group.rawValue+"/"+search

        if self.end_reached {
            failure(error: SettlePadError(errorCode: "end_reached", errorText: "End reached"))
        } else if  transactions.count  == 0 {
            //No transactions yet, so ignore request
        } else {
            getInternal(url, oneAtATime: true,
				success: {json in
					self.updateParams(json["data"]) //Update request parameters
					if json["data"]["transactions"].count == 0 {
						//no transactions, which is fine
						self.end_reached = true
					} else {
						for (_,subJson):(String, JSON) in json["data"]["transactions"] {
							self.transactions.append(Transaction(json: subJson)) //Add in rear
						}
					}
					success()
				},
				failure: {error in
					failure(error: error)
				}
			)
			
        }
    }
    
	func getUpdate(success: ()->(), failure: (error: SettlePadError) -> ()) {
        let url = "transactions/changes/\(oldestID)/\(newestID)/\(lastUpdate)"+"/"+String(nr_of_results)+"/"+self.group.rawValue+"/"+search
		
        getInternal(url, oneAtATime: true,
			success: {json in
				for (_,subJson):(String, JSON) in json["data"]["updates"]["transactions"] {
					let updatedTransaction = Transaction(json: subJson)
					for (i, transaction) in self.transactions.enumerate() {
						if transaction.transaction_id == updatedTransaction.transaction_id {
							self.transactions[i] = updatedTransaction
						}
					}
				}
				self.updateParams(json["data"]["updates"])
				
				var i = 0
				for (_,subJson):(String, JSON) in json["data"]["newer"]["transactions"] {
					self.transactions.insert(Transaction(json: subJson),atIndex: i) //Add in front
					i++
				}
				self.updateParams(json["data"]["newer"])
				success()
			},
			failure: {error in
				failure(error: error)
			}
		)
	}
    
	private func getInternal(url: String, oneAtATime: Bool, success: (json: JSON) ->(), failure: (error: SettlePadError) ->()) {

        let requestDate = NSDate()

		if oneAtATime && blockingRequestActive {
			failure(error: SettlePadError(errorCode: "another_request_pending", errorText: "Another request is already sent out"))
		} else {
			if oneAtATime {
				self.blockingRequestActive = true
			}
			HTTPWrapper.request(url, method: .GET, authenticateWithUser: activeUser!,
				success: {json in
					if oneAtATime {
						self.blockingRequestActive = false
					}
					if (requestDate.compare(self.lastRequest) != NSComparisonResult.OrderedAscending) { //requestDate is later than or equal to lastRequest
						self.lastRequest = requestDate
						success(json: json)
					} else {
						failure(error: SettlePadError(errorCode: "not_latest", errorText: "A request that was sent out later was returned before this request"))
					}
				},
				failure: { error in
					if oneAtATime {
						self.blockingRequestActive = false
					}
					failure(error: error)
				}
			)
		}
    }
	
	/**
	Updates the boundaries of the set of transactions that we received
	*/
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
	//TODO: kill the one above it not used anymore
	
	private func updateParams(json: JSON) {
		if let newestID = json["newest_id"].int {
			self.newestID = max(newestID,self.newestID)
		}
		if let oldestID = json["oldest_id"].int {
			if (self.oldestID == 0) {
				self.oldestID = oldestID
			} else {
				self.oldestID = min(oldestID,self.oldestID)
			}
		}
		if let lastUpdate = json["last_update"].int {
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
    
	func changeTransaction(action: String, transaction: Transaction, success: () -> (), failure: (error:SettlePadError)->()) {
        let url = "transactions/"+action+"/\(transaction.transaction_id!)/"
        HTTPWrapper.request(url, method: .POST, authenticateWithUser: activeUser!,
			success: {json in
				success()
			},
			failure: { error in
				failure(error: error)
			}
		)
    }
	
	//TODO: when to call this function?
	func updateStatus(success: (()->())? = nil, failure: ((error: SettlePadError)->())? = nil) {
		HTTPWrapper.request("status", method: .GET, authenticateWithUser: activeUser! ,
			success: {json in
				if let countUnreadOpen = json["data"]["unread"]["open"].int {
					self.countUnreadOpen = countUnreadOpen
				}
				if let countUnreadProcessed = json["data"]["unread"]["processed"].int {
					self.countUnreadProcessed = countUnreadProcessed
				}
				if let countUnreadCanceled = json["data"]["unread"]["canceled"].int {
					self.countUnreadCanceled = countUnreadCanceled
				}
				if let countOpen = json["data"]["open"].int {
					self.countOpen = countOpen
				}
				badgeCount = self.countUnreadOpen + self.countUnreadProcessed + self.countUnreadCanceled
					
				self.tabBarDelegate?.updateBadges()
				success?()
			},
			failure: { error in
				failure?(error: error)
			}
		)
	}
}

enum TransactionsStatusGroup: String {
	case Open = "open"
	case Processed = "processed"
	case Canceled = "canceled"
	case All = "all"
}
