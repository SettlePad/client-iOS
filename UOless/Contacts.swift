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
    var registeredContacts : [Contact] {
        get {
            return contacts.filter { $0.registered}
        }
    }
    var favoriteContacts : [Contact] {
        get {
            return contacts.filter { $0.favorite}
        }
    }

    var contactIdentifiers = [Dictionary<String,String>]() //Name, Identifier
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
        
        //update sorted list of identifiers
        contactIdentifiers.removeAll()
        for contact in contacts {
            for identifier in contact.identifiers {
                contactIdentifiers.append(["name":contact.friendlyName,"identifier":identifier])
            }
        }
        contactIdentifiers.sort({$0["name"] < $1["name"] }) //Sort by name ASC

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
                            self.addContact(Contact(fromDict: contactDict, registered: true), merge: false)
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
                            let email = emailID as! String
        
                            //Verify that email address is really an email address
                            if email.isEmail() {
                                emails.append(email)
                            }
                        }
                    }
                }
                
                addContact(Contact(id: nil, name: ABRecordCopyCompositeName(person).takeRetainedValue() as String, friendlyName: ABRecordCopyCompositeName(person).takeRetainedValue() as String, favorite: false, identifiers: emails, registered: false), merge: true)
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
    
    private func addContact(contact: Contact, merge: Bool) {
        if merge {
            //If merge, then check whether identifier already exists. If so: replace only friendlyname
            for index in stride(from: contact.identifiers.count - 1, through: 0, by: -1) {
                //Check whether identifier is present already
                var found = false
                for c in contacts {
                    if let i = find(c.identifiers, contact.identifiers[index]) {
                        //replace friendly name
                        c.friendlyName = contact.friendlyName
                        found = true
                    }
                }
                if found {
                    //remove identifier from contact
                    contact.identifiers.removeAtIndex(index)
                }
            }
            if contact.identifiers.count > 0 {
                //If there's anything left..
                contacts.append(contact)
            }
        } else {
            contacts.append(contact)
        }
    }
    
    func clear() {
        contacts = []
        contactIdentifiers = []
    }

}
