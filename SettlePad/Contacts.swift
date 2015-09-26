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
	private(set) var contacts = [Contact]()
	private(set) var contactIdentifiers = [Identifier]() //Identifier, Contact

	private var contactsUpdating: Bool = false
	
    var favoriteContacts : [Contact] {
        get {
            return contacts.filter { $0.favorite}
        }
    }

	func getIdentifier(identifierStr: String)->Identifier? {
		let returnArray = contactIdentifiers.filter {$0.identifierStr == identifierStr}
		return returnArray.first
	}
	
	var localStatus: ABAuthorizationStatus {
		get {
			return ABAddressBookGetAuthorizationStatus()
		}
	}
	
    
    func updateContacts(requestCompleted : (succeeded: Bool, error_msg: String?) -> ()) {
		//Update server contacts
		
		if contactsUpdating == false {
		contactsUpdating = true
			api.request("contacts", method:"GET", formdata: nil, secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
				if(!succeeded) {
					if let error_msg = data["text"] as? String {
						requestCompleted(succeeded: false,error_msg: error_msg)
					} else {
						requestCompleted(succeeded: false,error_msg: "Unknown error while refreshing contacts")
					}
				} else {
					self.contacts = []
					if let contactsArray = data["data"] as? [Dictionary <String, AnyObject>] {
						for contactDict in contactsArray {
							self.contacts.append(Contact(fromDict: contactDict, propagatedToServer: true))
						}
					}
					self.updateIdentifiers()
					requestCompleted(succeeded: true,error_msg: nil)
				}
				self.contactsUpdating = false
			}
		} else {
			requestCompleted(succeeded: false, error_msg: "Already refreshing")
		}
    }

		
    private func updateIdentifiers() {
        //Add server contacts
        contactIdentifiers.removeAll()
        for contact in contacts {
            for identifierStr in contact.identifiers {
				contactIdentifiers.append(Identifier(identifierStr: identifierStr,contact: contact))
            }
        }
		
		//Add local address book
		if (self.localStatus == .Authorized) {
			if let addressBook: ABAddressBookRef = createAddressBook() {
				//if let people = ABAddressBookCopyArrayOfAllPeople(addressBook)?.takeRetainedValue() as? [ABRecord] {
				if let people =  ABAddressBookCopyArrayOfAllPeople(addressBook)?.takeRetainedValue()  as NSArray? as? [ABRecordRef] {
					for person in people {
						var localName: String? = nil
						if let name = ABRecordCopyCompositeName(person)?.takeRetainedValue() as? String {
							localName = name
						}
						
						let emailMVR: ABMultiValueRef = ABRecordCopyValue(person, kABPersonEmailProperty).takeRetainedValue()
						for (var i = 0; i < ABMultiValueGetCount(emailMVR); i++) {
							if let email = ABMultiValueCopyValueAtIndex(emailMVR, i)?.takeRetainedValue() as? String {
								if email.isEmail() {
									if let existingIdentifier = getIdentifier(email) {
										existingIdentifier.localName = localName
									} else {
										contactIdentifiers.append(Identifier(identifierStr: email,localName: localName))
									}
								}
							}
						}
					}
				}
			}
		}
		
		//Sort
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
							self.updateIdentifiers()
                        }
                        requestCompleted(succeeded: granted)
                })
            }
        }
    }
	
	
	func addContact(contact: Contact, updateServer: Bool, requestCompleted: (succeeded: Bool, error_msg: String?) -> ()) {
		if (updateServer) {
			if contact.identifiers.count > 0 {
				contact.propagatedToServer = false
				contacts.append(contact)
				api.request("contacts/"+contact.identifiers[0], method:"POST", formdata: contact.toDict(), secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(succeeded) {
						if let registered = data["data"]?["registered"] as? Bool {
							contact.registered = registered
						}
						contact.propagatedToServer = true
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
		} else {
			contacts.append(contact)
		}
		self.updateIdentifiers()
	}
	
	func deleteContact(contact:Contact) {
		var row: Int?
		for (index,c) in contacts.enumerate() {
			if c == contact {
				row = index
			}
		}
		if row != nil {
			contacts.removeAtIndex(row!)
			self.updateIdentifiers()
			if contact.identifiers.count > 0 {
				api.request("contacts/"+contact.identifiers[0], method:"POST", formdata: ["identifier":""], secure:true) { (succeeded: Bool, data: NSDictionary) -> () in
					if(!succeeded) {
						if let error_msg = data["text"] as? String {
							print(error_msg)
						} else {
							print("Unknown error while removing contact")
						}
						
						//roll back removal
						self.contacts.append(contact)
						self.updateIdentifiers()
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
	var contact: Contact?
	var localName: String?
	
	var resultingName: String {
		get {
			var returnStr: String? = nil
			if localName != nil {
				returnStr = localName!
			}
			if contact != nil {
				if contact!.friendlyName != "" {
					returnStr = contact!.friendlyName
				}
				if returnStr == nil {
					returnStr = contact?.name
				}
			}
			if returnStr == nil {
				returnStr = identifierStr
			}
			return returnStr!
		}
	}
	
	init (identifierStr: String, contact: Contact) {
		self.identifierStr = identifierStr
		self.contact = contact
	}
	init (identifierStr: String, localName: String?) {
		self.identifierStr = identifierStr
		self.localName = localName
	}
}