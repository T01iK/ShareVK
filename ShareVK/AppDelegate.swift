//
//  AppDelegate.swift
//  ShareVK
//
//  Created by Анатолий Шулика on 28.10.16.
//  Copyright © 2016 Анатолий Шулика. All rights reserved.
//

import Cocoa
import SwiftyVK

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        _ = VKDelegation()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

