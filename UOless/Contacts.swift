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
        updateServerContacts()
        
        //And from the local address book
        if (ABAddressBookGetAuthorizationStatus() == .Authorized) {
            if let adressBook: ABAddressBookRef = createAddressBook() {
                updateLocalContacts(adressBook)
            }
        }
    }
    
    private func updateServerContacts() {
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
                            self.addContact(Contact(fromDict: contactDict))
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
    
    private func updateLocalContacts(addressBook: ABAddressBookRef) {
        if let people = ABAddressBookCopyArrayOfAllPeople(addressBook)?.takeRetainedValue() as? [ABRecord] {
            for person in people {
                var emails = [String]()
                if let emailProperty: ABMultiValueRef = ABRecordCopyValue(person, kABPersonEmailProperty)?.takeRetainedValue() {
                    if let allEmailIDs: NSArray = ABMultiValueCopyArrayOfAllValues(emailProperty)?.takeUnretainedValue() {
                        for emailID in allEmailIDs {
                            let email = emailID as String
        
                            //Verify that email address is really an email address
                            if email.isEmail() {
                                emails.append(email)
                            }
                        }
                    }
                }
                
                addContact(Contact(id: nil, name: ABRecordCopyCompositeName(person).takeRetainedValue(), friendlyName: ABRecordCopyCompositeName(person).takeRetainedValue(), favorite: false, identifiers: emails))
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
                        if granted {
                            self.updateLocalContacts(adressBook)
                        }
                        requestCompleted(succeeded: granted)
                })
            }
        }
    }
    
    private func addContact(contact: Contact) {
        contacts.append(contact)
    }
    

}
