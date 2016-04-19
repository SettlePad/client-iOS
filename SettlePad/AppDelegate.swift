//
//  AppDelegate.swift
//  SettlePad
//
//  Created by Rob Everhardt on 03/11/14.
//  Copyright (c) 2015 SettlePad. All rights reserved.
//

import UIKit
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GGLInstanceIDDelegate, GCMReceiverDelegate {

    var window: UIWindow?

	var connectedToGCM = false
	var subscribedToTopic = false
	var gcmSenderID: String?
	var registrationToken: String?
	var registrationOptions = [String: AnyObject]()
	
	let registrationKey = "onRegistrationCompleted"
	let messageKey = "onMessageReceived"
	let subscriptionTopic = "/topics/global"

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

		//setBadgeNumber(0)
		application.cancelAllLocalNotifications()
		
		// Register for remote notifications
			var configureError:NSError?
			GGLContext.sharedInstance().configureWithError(&configureError)
			assert(configureError == nil, "Error configuring Google services: \(configureError)")
			gcmSenderID = GGLContext.sharedInstance().configuration.gcmSenderID
			
			let settings: UIUserNotificationSettings =
				UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
			application.registerUserNotificationSettings(settings)
			application.registerForRemoteNotifications()
			
			let gcmConfig = GCMConfig.defaultConfig()
			gcmConfig.receiverDelegate = self
			GCMService.sharedInstance().startWithConfig(gcmConfig)
		
        return true
    }
	
	func application( application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData ) {
		
		
		// Create a config and set a delegate that implements the GGLInstaceIDDelegate protocol.
		let instanceIDConfig = GGLInstanceIDConfig.defaultConfig()
		instanceIDConfig.delegate = self
		// Start the GGLInstanceID shared instance with that config and request a registration
		// token to enable reception of notifications
		GGLInstanceID.sharedInstance().startWithConfig(instanceIDConfig)
		#if DEBUG
			registrationOptions = [kGGLInstanceIDRegisterAPNSOption:deviceToken,
			                       kGGLInstanceIDAPNSServerTypeSandboxOption:true]
		#else
			registrationOptions = [kGGLInstanceIDRegisterAPNSOption:deviceToken,
			                       kGGLInstanceIDAPNSServerTypeSandboxOption:false]
		#endif
		
		GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(gcmSenderID,
		                                                         scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
	}
	
	func registrationHandler(registrationToken: String!, error: NSError!) {
		if (registrationToken != nil) {
			self.registrationToken = registrationToken
			print("Registration Token: \(registrationToken)")
			self.subscribeToTopic()

			if activeUser != nil {
				activeUser!.registerAPNToken(registrationToken, success: {},failure: { error in
					print("Error while registering device token: "+error.errorText)
				})
			}
		} else {
			print("Registration to GCM failed with error: \(error.localizedDescription)")
		}
	}
	
	func onTokenRefresh() {
		// A rotation of the registration tokens is happening, so the app needs to request a new token.
		print("The GCM registration token needs to be changed.")
		GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(gcmSenderID, scope: kGGLInstanceIDScopeGCM,options: registrationOptions, handler: registrationHandler)
	}
	
	func subscribeToTopic() {
		// If the app has a registration token and is connected to GCM, proceed to subscribe to the
		// topic
		if(registrationToken != nil && connectedToGCM) {
			GCMPubSub.sharedInstance().subscribeWithToken(self.registrationToken, topic: subscriptionTopic,options: nil, handler: {(error:NSError?) -> Void in
				if let error = error {
					// Treat the "already subscribed" error more gently
					if error.code == 3001 {
						print("Already subscribed to \(self.subscriptionTopic)")
					} else {
						print("Subscription failed: \(error.localizedDescription)");
					}
				} else {
					self.subscribedToTopic = true;
					NSLog("Subscribed to \(self.subscriptionTopic)");
				}
			})
		}
	}
	
	func application( application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError ) {
		
		print("Registration for remote notification failed with error: \(error.localizedDescription)")
	}


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		
		GCMService.sharedInstance().disconnect()
		// [START_EXCLUDE]
		self.connectedToGCM = false
		// [END_EXCLUDE]
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		// Connect to the GCM server to receive non-APNS notifications
		GCMService.sharedInstance().connectWithHandler({(error:NSError?) -> Void in
			if let error = error {
				print("Could not connect to GCM: \(error.localizedDescription)")
			} else {
				self.connectedToGCM = true
				print("Connected to GCM")
				// [START_EXCLUDE]
				self.subscribeToTopic()
				// [END_EXCLUDE]
			}
		})
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
	
	func setBadgeNumber(number: Int) {
		//if UIDevice.currentDevice().systemVersion.compare("8.0", options: NSStringCompareOptions.NumericSearch) != NSComparisonResult.OrderedAscending {
				//As of 8.0
				if UIApplication.sharedApplication().currentUserNotificationSettings()!.types.intersect(UIUserNotificationType.Badge) != [] {
					UIApplication.sharedApplication().applicationIconBadgeNumber = number
				//} else {
				//	println("No permission to set badge number")
				}
		/*} else {
			UIApplication.sharedApplication().applicationIconBadgeNumber = number
		}*/
	}
	
	func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
		print("Notification received: \(userInfo)")
		// This works only if the app started the GCM service
		GCMService.sharedInstance().appDidReceiveMessage(userInfo);
		// Handle the received message

		if let data = userInfo["data"] as? JSON {
			print(data.rawString())
			activeUser?.transactions.processUnreadCounts(data)
		}
	}
	
	
	func willSendDataMessageWithID(messageID: String!, error: NSError!) {
		if (error != nil) {
			// Failed to send the message.
		} else {
			// Will send message, you can save the messageID to track the message
		}
	}
	
	func didSendDataMessageWithID(messageID: String!) {
		// Did successfully send message identified by messageID
	}
	// [END upstream_callbacks]
	
	func didDeleteMessagesOnServer() {
		// Some messages sent to this device were deleted on the GCM server before reception, likely
		// because the TTL expired. The client should notify the app server of this, so that the app
		// server can resend those messages.
	}
}

