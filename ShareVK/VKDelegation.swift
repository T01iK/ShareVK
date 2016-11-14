//
//  VKDelegation.swift
//  ShareVK
//
//  Created by Анатолий Шулика on 28.10.16.
//  Copyright © 2016 Анатолий Шулика. All rights reserved.
//

import SwiftyVK
import Cocoa

class VKDelegation: VKDelegate {
    let appID = "5691658"
    let scope = [VK.Scope.messages,.offline,.friends,.wall,.photos,.email,.audio,.docs,.groups,.video]
    
    
    
    init() {
        VK.configure(appID: appID, delegate: self)
    }
    
    
    
    func vkWillAuthorize() -> [VK.Scope] {
        return scope
    }
    
    
    
    func vkDidAuthorizeWith(parameters: Dictionary<String, String>) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "TestVkDidAuthorize"), object: nil)
        
        
    }
    
    
    
    
    func vkAutorizationFailedWith(error: VK.Error) {
        print("Autorization failed with error: \n\(error)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "TestVkDidNotAuthorize"), object: nil)
    }
    
    
    
    func vkDidUnauthorize() {}
    
    
    
    func vkShouldUseTokenPath() -> String? {
        return nil
    }
    
    
    
    func vkWillPresentView() -> NSWindow? {
        return NSApplication.shared().windows[0]
    }
    
    
}

