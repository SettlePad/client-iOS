//
//  Contacts.swift
//  UOless
//
//  Created by Rob Everhardt on 17/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation

class Contacts {
    var contacts = [Contact]()
    

    func updateContacts() {
        api.request("contacts", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(!succeeded) {
                if let error_msg = data["text"] as? String {
                    println(error_msg)
                } else {
                    println("Unknown error while refreshing contacts")
                }
            } else {
                if let contacts = data["data"] as? NSMutableArray {
                    for contactObj in contacts {
                        if let contactDict = contactObj as? NSDictionary {
                            self.contacts.append(Contact(fromDict: contactDict))
                        } else {
                            println("Cannot parse contact as dictionary")
                        }
                    }
                } else {
                    //no contacts, which is fine
                }
                
                
            }
        }
    }
}
