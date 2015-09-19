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
	
    var serverContacts : [Contact] {
        get {
            return contacts.filter {
				if $0.serverContact == .Yes || $0.serverContact == .Pending {
					return true
				} else {
					return false
				}
			}
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
                if let contacts = data["data"] as? [Dictionary <String, AnyObject>] {
                    for contactDict in contacts {
						self.addContactToList(Contact(fromDict: contactDict, serverContact: .Yes), updateIdentifiers: false)
                    }
					self.updateIdentifiers()
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
					addContactToList(Contact(id: nil, name: name, friendlyName: "", localName: name, favorite: false, autoAccept: .Manual, identifiers: emails, serverContact: .No), updateIdentifiers: false)
				}
            }
			self.updateIdentifiers()
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
		contactIdentifiers.sortInPlace({(left: Identifier, right: Identifier) -> Bool in
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
    
	func addContactToList(contact: Contact, updateIdentifiers: Bool) {
		//TODO: this function should be rethought! Its messed up, when adding and removing server contacts
		
        if contact.serverContact == .No {
			//Local contact
            //Check whether identifier already exists on a contact with an id. If so, only replace friendly name if that is not set. Only add if that is not the case.
            for index in (contact.identifiers.count - 1).stride(through: 0, by: -1) {
                //Check whether identifier is present already
                var found = false
				
                for c in contacts {
                    if let i = c.identifiers.indexOf(contact.identifiers[index]) {
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
			//TODO: this function overwrites local contacts. Should split it into two variables?
			//data must come directly from server
			var existingContact: Contact? = nil
			if contact.id != nil {
				existingContact = self.getContactByID(contact.id!)
			} else {
				existingContact = self.getContactByIdentifier(contact.identifiers[0])
			}
			if existingContact != nil {
				//update
				existingContact!.name = contact.name
				if contact.friendlyName != "" {
					existingContact!.setFriendlyName(contact.friendlyName, updateServer: false)
				}
				existingContact!.identifiers = contact.identifiers
				existingContact!.setFavorite(contact.favorite, updateServer: false)
				existingContact!.setAutoAccept(contact.autoAccept, updateServer: false)
			} else {
				contacts.append(contact)
			}
        }
		//Only update identifiers when just one contact is added. Otherwise, run it after adding all
		if (updateIdentifiers) {
			self.updateIdentifiers()
		}
    }
	
	func addContactToServer(contact: Contact, requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		if contact.id != nil || contact.identifiers.count > 0 {
			var url: String
			if contact.id != nil {
				url = "contacts/"+contact.id!.description
			} else {
				url = "contacts/"+contact.identifiers[0]
			}
			contact.serverContact = .Pending
			self.addContactToList(contact, updateIdentifiers: true)
			api.request(url, method:"POST", formdata: contact.toDict(), secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(succeeded) {
					contact.serverContact = .Yes
					if let userID = data["id"] as? Int {
						contact.id = userID
					}
					self.addContactToList(contact, updateIdentifiers: true)
					requestCompleted(succeeded: true,error_msg: nil)
				} else {
					if let error_msg = data["text"] as? String {
						requestCompleted(succeeded: false,error_msg: error_msg)
					} else {
						requestCompleted(succeeded: false,error_msg: "Unknown error while adding contact")
					}
				}
			}
		}
	}
	
	func deleteContact(contact:Contact) {
		var row: Int?
		for (index,c) in contacts.enumerate() {
			if c == contact {
				row = index
			}
		}
		if row != nil {
			var old_contact = contact
			contacts.removeAtIndex(row!)
			self.updateIdentifiers()
			if contact.id != nil || contact.identifiers.count > 0 {
				var url: String
				if contact.id != nil {
					url = "contacts/"+contact.id!.description
				} else {
					url = "contacts/"+contact.identifiers[0]
				}
				api.request(url, method:"POST", formdata: ["identifier":""], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(!succeeded) {
						if let error_msg = data["text"] as? String {
							print(error_msg)
						} else {
							print("Unknown error while removing contact")
						}
						
						//roll back removal
						self.addContactToList(contact, updateIdentifiers: true)
					}
				}
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