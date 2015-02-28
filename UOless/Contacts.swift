//
//  Contacts.swift
//  UOless
//
//  Created by Rob Everhardt on 17/02/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation
import AddressBook

class Contacts {
    var contacts = [Contact]()
    var localStatus: ABAuthorizationStatus {
        get {
            return ABAddressBookGetAuthorizationStatus()
        }
    }

    
    func updateContacts() {
        //From the UOless server
        api.request("contacts", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(!succeeded) {
                if let error_msg = data["text"] as? String {
                    println(error_msg)
                } else {
                    println("Unknown error while refreshing contacts")
                }
            } else {
                self.contacts.removeAll()
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
    
    private func createAddressBook() -> ABAddressBookRef?
    {
        var error: Unmanaged<CFError>?
        return ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
    }
    
    func requestLocalAccess(requestCompleted: (succeeded: Bool) -> ()) {
        //Check that status is still not determined
        if (ABAddressBookGetAuthorizationStatus() == .NotDetermined) {
            if let adressBook: ABAddressBookRef = createAddressBook() {
                ABAddressBookRequestAccessWithCompletion(adressBook,
                    {(granted: Bool, error: CFError!) in
                        requestCompleted(succeeded: granted);
                })
            }
        }
    }
    
}
