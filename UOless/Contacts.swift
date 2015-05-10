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
	
	func getContactByID(id: Int)->Contact? {
		let returnArray = contacts.filter { $0.id == id}
		return returnArray.first
	}
	
    func updateContacts(requestCompleted: () -> ()) {
        //From the UOless server
        updateServerContacts() {()->() in
            
            //From the local address book, once the server contacts have loaded
            if (ABAddressBookGetAuthorizationStatus() == .Authorized) {
                if let addressBook: ABAddressBookRef = self.createAddressBook() {
                    self.updateLocalContacts(addressBook)
                }
            }

            self.updateIdentifiers()
			self.updateAutoLimits(){()->() in
				requestCompleted()
			}
        }
    }
    
    private func updateServerContacts(requestCompleted: () -> ()) {
        api.request("contacts", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(!succeeded) {
                if let error_msg = data["text"] as? String {
                    println(error_msg)
                } else {
                    println("Unknown error while refreshing contacts")
                }
            } else {

                self.contacts = []
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
            requestCompleted()
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
	
	private func updateAutoLimits(requestCompleted : () -> ()) {
		api.request("autolimits", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
			if(!succeeded) {
				if let error_msg = data["text"] as? String {
					println(error_msg)
				} else {
					println("Unknown error while refreshing autolimits")
				}
			} else {
				if let contactsLimits = data["data"] as? Dictionary <String, Dictionary <String, Double> > {
					for (contactID,contactLimits) in contactsLimits {
						for (currencyString,limitDouble) in contactLimits {
							if let currency = Currency(rawValue: currencyString) {
								if let contactIDInt = contactID.toInt() {
									if let contact = self.getContactByID(contactIDInt) {
										contact.addLimit(currency, limit: limitDouble, updateServer: false)
									} else {
										println("Contact with ID not found: "+contactID)
									}
								} else {
									println("Contact ID no Int: "+contactID)
								}
							} else {
								println("Unknown currency: "+currencyString)
							}
						}
					}
				} else {
					println("Cannot parse limit as dictionary, might be that there are no limits")
				}
			}
			requestCompleted()
		}
	}
	
    private func updateIdentifiers() {
        //update sorted list of identifiers
        contactIdentifiers.removeAll()
        for contact in contacts {
            for identifier in contact.identifiers {
                contactIdentifiers.append(["name":contact.friendlyName,"identifier":identifier])
            }
        }
        contactIdentifiers.sort({$0["name"] < $1["name"] }) //Sort by name ASC
    }
        
    private func createAddressBook() -> ABAddressBookRef?
    {
        var error: Unmanaged<CFError>?
        return ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
    }
    
    func requestLocalAccess(requestCompleted: (succeeded: Bool) -> ()) {
        //Check that status is still not determined
        if (ABAddressBookGetAuthorizationStatus() == .NotDetermined) {
            if let addressBook: ABAddressBookRef = createAddressBook() {
                ABAddressBookRequestAccessWithCompletion(addressBook,
                    {(granted: Bool, error: CFError!) in
                        if granted {
                            self.updateLocalContacts(addressBook)
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
