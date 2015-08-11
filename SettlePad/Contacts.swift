//
//  Contacts.swift
//  SettlePad
//
//  Created by Rob Everhardt on 17/02/15.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import Foundation
import AddressBook

class Contacts {
	//Save contacts in CoreData
	
    private(set) var contacts = [Contact]()
	private var contactsUpdating: Bool = false
	
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


    var contactIdentifiers = [Identifier]() //Identifier, Contact
	
    var localStatus: ABAuthorizationStatus {
        get {
            return ABAddressBookGetAuthorizationStatus()
        }
    }
	
	func getContactByID(id: Int)->Contact? {
		let returnArray = contacts.filter { $0.id == id}
		return returnArray.first
	}

	func getContactByIdentifier(identifierStr: String)->Contact? {
		let returnArray = contactIdentifiers.filter {$0.identifierStr == identifierStr}
		return returnArray.first?.contact
	}
	
    func updateContacts(requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		//From the server
		if contactsUpdating == false {
			contactsUpdating = true
			updateServerContacts() {(succeeded: Bool, error_msg: String?) -> () in
				//From the local address book, once the server contacts have loaded
				if (ABAddressBookGetAuthorizationStatus() == .Authorized) {
					if let addressBook: ABAddressBookRef = self.createAddressBook() {
						self.updateLocalContacts(addressBook)
					}
				}

				self.updateIdentifiers()
				self.contactsUpdating = false
				requestCompleted(succeeded: succeeded, error_msg: error_msg)
			}
		} else {
			requestCompleted(succeeded: false, error_msg: "Already refreshing")
		}
    }
    
    private func updateServerContacts(requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
        api.request("contacts", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
            if(!succeeded) {
                if let error_msg = data["text"] as? String {
					requestCompleted(succeeded: false,error_msg: error_msg)
				} else {
					requestCompleted(succeeded: false,error_msg: "Unknown error while refreshing contacts")
                }
            } else {

                self.contacts = []
                if let contacts = data["data"] as? Dictionary <String, Dictionary <String, AnyObject> > {
                    for (keyString,contactDict) in contacts {
                        //if let contactDict = contactObj as? NSDictionary {
                            self.addContact(Contact(fromDict: contactDict, registered: true))
                        //} else {
                            //println("Cannot parse contact as dictionary")
                        //}
                    }
                } else {
                    //no contacts, which is fine
                }
				requestCompleted(succeeded: true,error_msg: nil)
			}

        }
    }
    
    private func updateLocalContacts(addressBook: ABAddressBookRef) {
        if let people = ABAddressBookCopyArrayOfAllPeople(addressBook)?.takeRetainedValue() as? [ABRecord] {
            for person in people {
                var emails = [String]()
				
				let emailMVR: ABMultiValueRef = ABRecordCopyValue(person, kABPersonEmailProperty).takeRetainedValue()
				for (var i = 0; i < ABMultiValueGetCount(emailMVR); i++) {
					if let email = ABMultiValueCopyValueAtIndex(emailMVR, i)?.takeRetainedValue() as? String {
						if email.isEmail() {
							emails.append(email)
						}
					}
				}
				
				if let name = ABRecordCopyCompositeName(person)?.takeRetainedValue() as? String {
					addContact(Contact(id: nil, name: name, friendlyName: "", localName: name, favorite: false, autoAccept: .Manual, identifiers: emails, registered: false))
				}
            }
        }
    }
	
	func updateAutoLimits(requestCompleted : () -> ()) {
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
				//} else {
					//println("Cannot parse limit as dictionary, might be that there are no limits")
				}
			}
			requestCompleted()
		}
	}
	
    private func updateIdentifiers() {
        //update sorted list of identifiers
        contactIdentifiers.removeAll()
        for contact in contacts {
            for identifierStr in contact.identifiers {
				contactIdentifiers.append(Identifier(identifierStr: identifierStr,contact: contact))
            }
        }
		contactIdentifiers.sort({(left: Identifier, right: Identifier) -> Bool in
			left.identifierStr.localizedCaseInsensitiveCompare(right.identifierStr) == NSComparisonResult.OrderedDescending})
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
							self.updateIdentifiers()
                        }
                        requestCompleted(succeeded: granted)
                })
            }
        }
    }
    
    func addContact(contact: Contact) {
        if contact.id == nil {
			//Local contact
            //Check whether identifier already exists on a contact with an id. If so, only replace friendly name if that is not set. Only add if that is not the case.
            for index in stride(from: contact.identifiers.count - 1, through: 0, by: -1) {
                //Check whether identifier is present already
                var found = false
                for c in contacts {
                    if let i = find(c.identifiers, contact.identifiers[index]) {
                        //replace friendly name
						c.localName = contact.localName
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
			//data must come directly from server
			if let existingContact = self.getContactByID(contact.id!) {
				//update
				existingContact.name = contact.name
				if contact.friendlyName != "" {
					existingContact.setFriendlyName(contact.friendlyName, updateServer: false)
				}
				existingContact.identifiers = contact.identifiers
				existingContact.setFavorite(contact.favorite, updateServer: false)
				existingContact.setAutoAccept(contact.autoAccept, updateServer: false)
			} else {
				contacts.append(contact)
			}
        }
    }
    
    func clear() {
        contacts = []
        contactIdentifiers = []
    }

}

class Identifier {
	var identifierStr: String
	var contact: Contact
	
	init (identifierStr: String, contact: Contact) {
		self.identifierStr = identifierStr
		self.contact = contact
	}
}