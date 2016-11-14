//
//  ViewController.swift
//  ShareVK
//
//  Created by Анатолий Шулика on 28.10.16.
//  Copyright © 2016 Анатолий Шулика. All rights reserved.
//

import Cocoa
import SwiftyVK

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.AuthOK), name: NSNotification.Name(rawValue: "TestVkDidAuthorize"), object: nil)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func AuthOK() {
        LoginButton.title = "Выйти из ВКонтакте"
        let profileRequest = VK.API.Users.get()
        profileRequest.progressBlock = { done, total in
            DispatchQueue.main.async(execute: {
                self.currentUserLabel.stringValue = "вход..."
            })
        }
        profileRequest.successBlock = { response in
            DispatchQueue.main.async(execute: {
                self.currentUserLabel.stringValue = response[0, "first_name"].string! + " " + response[0, "last_name"].string!
            })
        }
        profileRequest.send()
    }

    
    @IBOutlet weak var LoginButton: NSButton!
    @IBAction func LoginButtonPressed(_ sender: NSButton) {
        if VK.state != .authorized {
            VK.logIn()
        }
        else {
            VK.logOut()
            LoginButton.title = "Войти во ВКонтакте"
            currentUserLabel.stringValue = "не авторизовано"
        }
    }

    @IBOutlet weak var currentUserLabel: NSTextField!

}

