//
//  transactions.swift
//  UOless
//
//  Created by Rob Everhardt on 31/12/14.
//  Copyright (c) 2014 UOless. All rights reserved.
//

import Foundation

class TransactionsController {
    var documentList = NSBundle.mainBundle().pathForResource("settings", ofType:"plist")
    var settingsDictionary: AnyObject? = nil
    
    var nr_of_results: String
    var search = ""
    var requestParams = ["newest_id" : "", "oldest_id" : "", "last_update" : ""]
    var already_getting = false
    var api: APIController
    
    init(api: APIController) {
        self.api = api
        settingsDictionary = NSDictionary(contentsOfFile: documentList!)
        nr_of_results = String(settingsDictionary!["transactions_nr_of_results"]! as Int)
    }
    
    func get(search: String, requestCompleted : (succeeded: Bool, transactions: NSArray?, msg: String?) -> ()) {
        self.search = search
        var url = "transactions/initial/"+nr_of_results+"/"+search
        getInternal(url){ (succeeded: Bool, transactions: NSArray?, msg: String?) -> () in
            requestCompleted(succeeded: succeeded,transactions: transactions,msg: msg)
        }
    }
    
    func getMore(requestCompleted : (succeeded: Bool, transactions: NSArray?, msg: String?) -> ()) {
        var url = "transactions/older/"+requestParams["oldest_id"]!+"/"+nr_of_results+"/"+search
        getInternal(url){ (succeeded: Bool, transactions: NSArray?, msg: String?) -> () in
            requestCompleted(succeeded: succeeded,transactions: transactions,msg: msg)
        }
    }
    
    private func getInternal(url: String, requestCompleted : (succeeded: Bool, transactions: NSArray?, msg: String?) -> ()) {
        if (self.already_getting) {
            //cancel request
            requestCompleted(succeeded: false,transactions: nil,msg: "Already performing a request")
        } else if (api.is_loggedIn() == false) {
            requestCompleted(succeeded: false,transactions: nil,msg: "Not logged in")            
        } else {
            
            already_getting = true
            api.request(url, method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
                var proceedRequest = true
                if(succeeded) {
                    var expectedKeys: [String] = ["newest_id", "oldest_id","last_update"]
                    for expectedKey in expectedKeys {
                        if let keyValue = data["data"]![expectedKey] as? Int {
                            self.requestParams[expectedKey] = String(keyValue)
                        } else {
                            requestCompleted(succeeded: false, transactions: nil,msg: "Unexpected server return: parameter "+expectedKey+" missing")
                            var proceedRequest = false
                        }
                    }
                    if (proceedRequest){
                        if let transactionsArray = data["data"]!["transactions"] as? NSArray {
                            requestCompleted(succeeded: true,transactions:transactionsArray,msg:nil)
                        } else {
                            requestCompleted(succeeded: false,transactions: nil, msg: "No transaction parameter")
                        }
                    }
                } else {
                    if let msg = data["text"] as? String {
                        requestCompleted(succeeded: false,transactions: nil, msg: msg)
                    } else {
                        requestCompleted(succeeded: false,transactions: nil, msg: "Unknown error")
                    }
                }
              self.already_getting = false
            }
        }
    }
    
}
