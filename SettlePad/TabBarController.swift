//
//  TabBarController.swift
//  SettlePad
//
//  Created by Rob Everhardt on 24/10/15.
//  Copyright © 2015 SettlePad. All rights reserved.
//

import UIKit

protocol TabBarDelegate {
	func updateBadges()
}


class TabBarController: UITabBarController, TabBarDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		activeUser?.transactions.tabBarDelegate = self
		updateBadges()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	func updateBadges() {
		//Update badgeCount
		let tabArray = tabBar.items as NSArray!
		let tabItem = tabArray.objectAtIndex(1) as! UITabBarItem
		dispatch_async(dispatch_get_main_queue()) {
			if let badgeCount = activeUser?.transactions.badgeCount {
				if badgeCount > 0 {
					tabItem.badgeValue = badgeCount.description
				} else {
					tabItem.badgeValue = nil
				}
			} else {
				tabItem.badgeValue = nil
			}
		}
		
		//Also update appBadge
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, badgeCount = activeUser?.transactions.badgeCount {
			appDelegate.setBadgeNumber(badgeCount)
		}
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
