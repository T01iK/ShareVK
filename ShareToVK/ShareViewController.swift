//
//  ShareViewController.swift
//  ShareToVK
//
//  Created by Анатолий Шулика on 31.10.16.
//  Copyright © 2016 Анатолий Шулика. All rights reserved.
//

import Cocoa
import SwiftyVK
import Social

class ConversationList {
    var IDs = [String]()
    var isConference = [Bool]()
    var isGroup = [Bool]()
    var names = [String]()
    var conversationsCount = Int()
    var withoutNames = String()
    var groupsWithoutNames = String()
    
}

class GroupsList {
    var IDs = [String]()
    var names = [String]()
    var groupsCount = Int()
    
}

let conversations = ConversationList()
let groups = GroupsList()
var currentUserID = ""
var typeID = ""
var attachmentsCount = 0
var attachmentsFinalString = ""
var attachmentFileURL = ""
var attachmentFileName = ""
var attachmentFileNameWithoutExt = ""
var attachmentFileExt = ""
var attachmentsStrings = [String]()
var attaсhmentsTitles = [String]()
var isCanceled = Bool()


class ShareViewController: NSViewController {
    
    
    override var nibName: String? {
        return "ShareViewController"
    }
    
    func closeComposeWindow() {
        let outputItem = self.extensionContext!.inputItems[0] as! NSExtensionItem
        let outputItems = [outputItem]
        self.extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
    }
    
    override func loadView() {
        super.loadView()
        _ = VKDelegation()
        VK.logIn()
        conversations.IDs.removeAll()
        conversations.names.removeAll()
        conversations.isConference.removeAll()
        conversations.isGroup.removeAll()
        conversations.groupsWithoutNames = ""
        conversations.withoutNames = ""
        groups.IDs.removeAll()
        groups.names.removeAll()
        attachmentsStrings.removeAll()
        attachmentsFinalString = ""
        let profileRequest = VK.API.Users.get()
        profileRequest.successBlock = { response in
            currentUserID = String(response[0, "id"].intValue)
            DispatchQueue.main.async(execute: {
                self.currentUserLabel.stringValue = response[0, "first_name"].string! + " " + response[0, "last_name"].string!
                self.currentUserLabel.isHidden = false
            })
            
        }
        profileRequest.send()
        
        let requestGroups = VK.API.Groups.get([VK.Arg.extended : "1", VK.Arg.filter : "editor", VK.Arg.count : "50"])
        requestGroups.successBlock = { response in
            self.progressFlower.startAnimation(1)
            groups.groupsCount = response["count"].intValue
            for currentGroup in 0...groups.groupsCount-1 {
                self.toSwitch.isEnabled = false
                groups.IDs.append(String(response["items"][currentGroup, "id"].intValue))
                groups.names.append(response["items"][currentGroup, "name"].string!)
            }
            if self.audienceSwitch.indexOfSelectedItem == 1 {
                self.toSwitch.addItems(withTitles: groups.names)
            }
            if self.audienceSwitch.indexOfSelectedItem == 2 {
                self.toSwitch.addItems(withTitles: conversations.names)
            }
        }
        requestGroups.send()
        
        let requestConversations = VK.API.Messages.getDialogs([VK.Arg.count : "50", VK.Arg.previewLength : "1"])
        requestConversations.successBlock = {response in
            self.progressFlower.startAnimation(1)
            conversations.conversationsCount = response["count"].intValue
            print(conversations.conversationsCount)
            conversations.withoutNames = ""
            for currentConversation in 0...conversations.conversationsCount-1 {
                self.toSwitch.isEnabled = false
                if response["items"][currentConversation, "message", "chat_id"] != nil {
                    conversations.isConference.append(true)
                    conversations.isGroup.append(false)
                    conversations.IDs.append(String(response["items"][currentConversation, "message", "chat_id"].intValue))
                    conversations.names.append(response["items"][currentConversation, "message", "title"].string!)
                }
                else {
                    conversations.isConference.append(false)
                    conversations.IDs.append(String(response["items"][currentConversation, "message", "user_id"].intValue))
                    if conversations.IDs[currentConversation].contains("-") {
                        conversations.isGroup.append(true)
                    }
                    else { conversations.isGroup.append(false) }
                    conversations.names.append("")
                    if conversations.isGroup[currentConversation] == false {
                        if conversations.withoutNames == "" {
                            conversations.withoutNames = conversations.IDs[currentConversation]
                        }
                        else {
                            conversations.withoutNames = conversations.withoutNames + "," + conversations.IDs[currentConversation]
                        }
                    }
                    if conversations.isGroup[currentConversation] == true {
                        var groupID = conversations.IDs[currentConversation]
                        groupID.remove(at: groupID.startIndex)
                        if conversations.groupsWithoutNames == "" {
                            conversations.groupsWithoutNames = groupID
                        }
                        else {
                            conversations.groupsWithoutNames = conversations.groupsWithoutNames + "," + groupID
                        }
                    }
                }
                
            }
            let requestUserInfo = VK.API.Groups.getById([VK.Arg.groupIds : conversations.groupsWithoutNames])
            requestUserInfo.successBlock = { response in
                var currentItem = 0
                for currentConversation in 0...conversations.conversationsCount-1 {
                    if conversations.isGroup[currentConversation] == true {
                        conversations.names[currentConversation] = response[currentItem, "name"].string!
                        currentItem = currentItem + 1
                    }
                }
            }
            requestUserInfo.asynchronous = false
            requestUserInfo.send()
            
            let requestGroupsInfo = VK.API.Users.get([VK.Arg.userIDs : conversations.withoutNames])
            requestGroupsInfo.successBlock = { response in
                var currentItem = 0
                for currentConversation in 0...conversations.conversationsCount-1 {
                    if conversations.isConference[currentConversation] == false && conversations.isGroup[currentConversation] == false {
                        conversations.names[currentConversation] = response[currentItem, "first_name"].string! + " " + response[currentItem, "last_name"].string!
                        currentItem = currentItem + 1
                    }
                }
                DispatchQueue.main.async(execute: {
                    self.sendButton.isEnabled = true
                })
                
            }
            requestGroupsInfo.asynchronous = false
            requestGroupsInfo.send()
            
            if self.audienceSwitch.indexOfSelectedItem == 1 {
                self.toSwitch.addItems(withTitles: groups.names)
            }
            if self.audienceSwitch.indexOfSelectedItem == 2 {
                self.toSwitch.addItems(withTitles: conversations.names)
            }
            DispatchQueue.main.async(execute: {
                self.progressFlower.stopAnimation(1)
                self.toSwitch.isEnabled = true
            })
            
        }
        requestConversations.send()
        
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            NSLog("Attachments = %@", attachments as NSArray)
        } else {
            NSLog("No Attachments")
        }
        let outputItem = self.extensionContext!.inputItems[0] as! NSExtensionItem
        let attachments = outputItem.attachments as? [NSItemProvider]
        attachmentsCount = (attachments?.count)!
        var numberOfPreviews = 0
        for attachment: NSItemProvider in attachments! {
            if attachment.hasItemConformingToTypeIdentifier("public.url") {
                attachment.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) in
                    if let shareURL = url as? NSURL {
                        if (shareURL.absoluteString?.contains("file"))! {
                            attachmentFileURL = shareURL.absoluteString!
                            attachmentFileName = String((URL(string: String(attachmentFileURL)!)!.standardizedFileURL.lastPathComponent))
                            attachmentFileNameWithoutExt = self.removeExtensionFromFilename(file: attachmentFileName)
                            attaсhmentsTitles.append(attachmentFileNameWithoutExt)
                            attachmentFileExt = String((URL(string: String(attachmentFileURL)!)!.standardizedFileURL.pathExtension))
                            if attachmentFileExt != "" && attachmentFileExt != "mp3" && attachmentFileExt != "gif" && attachmentFileExt != "png" && attachmentFileExt != "jpg" && attachmentFileExt != "jpeg" && attachmentFileExt != "3gp" && attachmentFileExt != "avi" && attachmentFileExt != "flv" && attachmentFileExt != "mov" && attachmentFileExt != "mp4" && attachmentFileExt != "mpg" && attachmentFileExt != "mpeg" && attachmentFileExt != "wmv" {
                                print("FOUND SOME FILE")
                                var attachmentRelativePath = URL(fileURLWithPath: attachmentFileURL).relativePath
                                attachmentRelativePath.removeSubrange(attachmentRelativePath.startIndex..<attachmentRelativePath.index(attachmentRelativePath.startIndex, offsetBy: 5))
                                let shareData = try? Data(contentsOf: URL(fileURLWithPath: attachmentRelativePath))
                                let previewImage = NSImageView()
                                previewImage.frame = CGRect(x: 17 + numberOfPreviews * 52, y: 78, width: 50, height: 50)
                                previewImage.imageFrameStyle = .grayBezel
                                previewImage.image = #imageLiteral(resourceName: "docLogo.png")
                                DispatchQueue.main.async(execute: {
                                    self.view.addSubview(previewImage)
                                })
                                let uploadProgressBar = NSProgressIndicator()
                                uploadProgressBar.frame = CGRect(x: 20 + numberOfPreviews * 52, y: 74, width: 44, height: 20)
                                uploadProgressBar.controlSize = .regular
                                uploadProgressBar.isIndeterminate = false
                                uploadProgressBar.doubleValue = 0
                                uploadProgressBar.layer?.zPosition = 1
                                DispatchQueue.main.async(execute: {
                                    self.view.addSubview(uploadProgressBar)
                                })
                                
                                let title = attaсhmentsTitles[numberOfPreviews]
                                numberOfPreviews = numberOfPreviews + 1
                                
                                let uploadDocument = VK.API.Upload.document(Media(documentData: shareData!, type: attachmentFileExt), title: title)
                                uploadDocument.progressBlock = {done, total in
                                    NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.userCanceled), name: NSNotification.Name(rawValue: "CancelUpload"), object: nil)
                                    if isCanceled == true { uploadDocument.cancel() }
                                    DispatchQueue.main.async(execute: {
                                        uploadProgressBar.isHidden = false
                                        self.sendButton.isEnabled = false
                                        uploadProgressBar.maxValue = Double(total)
                                        uploadProgressBar.doubleValue = Double(done)
                                    })
                                }
                                uploadDocument.successBlock = {response in
                                    if uploadDocument.cancelled == false {
                                        DispatchQueue.main.async(execute: {
                                            uploadProgressBar.isHidden = true
                                            self.sendButton.isEnabled = true
                                        })
                                        print(response)
                                        attachmentsStrings.append("doc" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                                    }
                                    else {
                                        self.deleteItemFromServer(itemString: "doc" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                                    }
                                }
                                uploadDocument.errorBlock = {error in print("SwiftyVK: uploadDocument fail \n \(error)")}
                                uploadDocument.send()
                                
                                
                            }
                        }
                        else {
                            self.commentText.string = shareURL.absoluteString
                            attachmentsStrings.append(shareURL.absoluteString!)
                        }
                    }
                })
            }
            if attachment.hasItemConformingToTypeIdentifier("public.png") || attachment.hasItemConformingToTypeIdentifier("public.jpeg") || attachment.hasItemConformingToTypeIdentifier("public.jpg") {
                if attachment.hasItemConformingToTypeIdentifier("public.png") { typeID = "public.png" }
                if attachment.hasItemConformingToTypeIdentifier("public.jpeg") { typeID = "public.jpeg" }
                if attachment.hasItemConformingToTypeIdentifier("public.jpg") { typeID = "public.jpg" }
                attachment.loadItem(forTypeIdentifier: typeID, options: nil, completionHandler: { (image, error) in
                    if let shareImageData = image as? Data {
                        let shareImage = NSImage(data: shareImageData)
                        let previewImage = NSImageView()
                        previewImage.frame = CGRect(x: 17 + numberOfPreviews * 52, y: 78, width: 50, height: 50)
                        previewImage.imageFrameStyle = .grayBezel
                        previewImage.image = shareImage
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(previewImage)
                        })
                        let uploadProgressBar = NSProgressIndicator()
                        uploadProgressBar.frame = CGRect(x: 20 + numberOfPreviews * 52, y: 74, width: 44, height: 20)
                        uploadProgressBar.controlSize = .regular
                        uploadProgressBar.isIndeterminate = false
                        uploadProgressBar.doubleValue = 0
                        uploadProgressBar.layer?.zPosition = 1
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(uploadProgressBar)
                        })
                        
                        
                        numberOfPreviews = numberOfPreviews + 1
                        
                        let shareImageMedia = Media(imageData: shareImageData, type: self.grabImageType(typeString: typeID))
                        let uploadPhoto = VK.API.Upload.Photo.toWall.toUser(shareImageMedia, userId: currentUserID)
                        uploadPhoto.progressBlock = {done, total in
                            NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.userCanceled), name: NSNotification.Name(rawValue: "CancelUpload"), object: nil)
                            if isCanceled == true { uploadPhoto.cancel() }
                            DispatchQueue.main.async(execute: {
                                uploadProgressBar.isHidden = false
                                self.sendButton.isEnabled = false
                                uploadProgressBar.maxValue = Double(total)
                                uploadProgressBar.doubleValue = Double(done)
                            })
                            
                        }
                        uploadPhoto.successBlock = {response in
                            if uploadPhoto.cancelled == false {
                                DispatchQueue.main.async(execute: {
                                    uploadProgressBar.isHidden = true
                                    self.sendButton.isEnabled = true
                                })
                                print(response)
                                attachmentsStrings.append("photo" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                            }
                            else {
                                self.deleteItemFromServer(itemString: "photo" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                            }
                        }
                        uploadPhoto.errorBlock = {error in print("SwiftyVK: uploadPhoto fail \n \(error)")}
                        uploadPhoto.send()
                    }
                })
            }
            if attachment.hasItemConformingToTypeIdentifier("com.compuserve.gif") {
                typeID = "com.compuserve.gif"
                attachment.loadItem(forTypeIdentifier: typeID, options: nil, completionHandler: { (gif, error) in
                    if let shareGifData = gif as? Data {
                        //let title = attachmentFileName
                        let previewImage = NSImageView()
                        previewImage.frame = CGRect(x: 17 + numberOfPreviews * 52, y: 78, width: 50, height: 50)
                        previewImage.imageFrameStyle = .grayBezel
                        previewImage.image = #imageLiteral(resourceName: "gifLogo.png")
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(previewImage)
                        })
                        let uploadProgressBar = NSProgressIndicator()
                        uploadProgressBar.frame = CGRect(x: 20 + numberOfPreviews * 52, y: 74, width: 44, height: 20)
                        uploadProgressBar.controlSize = .regular
                        uploadProgressBar.isIndeterminate = false
                        uploadProgressBar.doubleValue = 0
                        uploadProgressBar.layer?.zPosition = 1
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(uploadProgressBar)
                        })
                        
                        
                        numberOfPreviews = numberOfPreviews + 1
                        
                        let uploadGIF = VK.API.Upload.document(Media(documentData: shareGifData, type: "gif"), title: attaсhmentsTitles[numberOfPreviews-1])
                        uploadGIF.progressBlock = {done, total in
                            NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.userCanceled), name: NSNotification.Name(rawValue: "CancelUpload"), object: nil)
                            if isCanceled == true { uploadGIF.cancel() }
                            DispatchQueue.main.async(execute: {
                                uploadProgressBar.isHidden = false
                                self.sendButton.isEnabled = false
                                uploadProgressBar.maxValue = Double(total)
                                uploadProgressBar.doubleValue = Double(done)
                            })
                        }
                        uploadGIF.successBlock = {response in
                            if uploadGIF.cancelled == false {
                                DispatchQueue.main.async(execute: {
                                    uploadProgressBar.isHidden = true
                                    self.sendButton.isEnabled = true
                                })
                                print(response)
                                attachmentsStrings.append("doc" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                            }
                            else {
                                self.deleteItemFromServer(itemString: "doc" + String(response[0,"owner_id"].intValue) + "_" + String(response[0,"id"].intValue))
                            }
                        }
                        uploadGIF.errorBlock = {error in print("SwiftyVK: uploadGif fail \n \(error)")}
                        uploadGIF.send()
                    }
                })
            }
            if attachment.hasItemConformingToTypeIdentifier("public.mp3") {
                attachment.loadItem(forTypeIdentifier: "public.mp3", options: nil, completionHandler: { (music, error) in
                    if let shareMusicData = music as? Data {
                        let previewImage = NSImageView()
                        previewImage.frame = CGRect(x: 17 + numberOfPreviews * 52, y: 78, width: 50, height: 50)
                        previewImage.imageFrameStyle = .grayBezel
                        previewImage.image = #imageLiteral(resourceName: "musicLogo.png")
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(previewImage)
                        })
                        let uploadProgressBar = NSProgressIndicator()
                        uploadProgressBar.frame = CGRect(x: 20 + numberOfPreviews * 52, y: 74, width: 44, height: 20)
                        uploadProgressBar.controlSize = .regular
                        uploadProgressBar.isIndeterminate = false
                        uploadProgressBar.doubleValue = 0
                        uploadProgressBar.layer?.zPosition = 1
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(uploadProgressBar)
                        })
                        
                        
                        numberOfPreviews = numberOfPreviews + 1
                        
                        let uploadMusic = VK.API.Upload.audio(Media(audioData: shareMusicData))
                        uploadMusic.progressBlock = {done, total in
                            NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.userCanceled), name: NSNotification.Name(rawValue: "CancelUpload"), object: nil)
                            if isCanceled == true { uploadMusic.cancel() }
                            DispatchQueue.main.async(execute: {
                                uploadProgressBar.isHidden = false
                                self.sendButton.isEnabled = false
                                uploadProgressBar.maxValue = Double(total)
                                uploadProgressBar.doubleValue = Double(done)
                            })
                        }
                        uploadMusic.successBlock = {response in
                            if uploadMusic.cancelled == false {
                                DispatchQueue.main.async(execute: {
                                    uploadProgressBar.isHidden = true
                                    self.sendButton.isEnabled = true
                                })
                                print(response)
                                attachmentsStrings.append("audio" + String(response["owner_id"].intValue) + "_" + String(response["id"].intValue))
                            }
                            else {
                                self.deleteItemFromServer(itemString: "audio" + String(response["owner_id"].intValue) + "_" + String(response["id"].intValue))
                            }
                        }
                        uploadMusic.errorBlock = {error in print("SwiftyVK: uploadMusic fail \n \(error)")}
                        uploadMusic.send()
                    }
                })
            }
            if attachment.hasItemConformingToTypeIdentifier("public.3gpp") || attachment.hasItemConformingToTypeIdentifier("public.avi") || attachment.hasItemConformingToTypeIdentifier("com.adobe.flash.video") || attachment.hasItemConformingToTypeIdentifier("com.apple.quicktime-movie") || attachment.hasItemConformingToTypeIdentifier("public.mpeg-4") || attachment.hasItemConformingToTypeIdentifier("public.mpeg") || attachment.hasItemConformingToTypeIdentifier("com.microsoft.windows-media-wmv") {
                if attachment.hasItemConformingToTypeIdentifier("public.3gpp") { typeID = "public.3gpp" }
                if attachment.hasItemConformingToTypeIdentifier("public.avi") { typeID = "public.avi" }
                if attachment.hasItemConformingToTypeIdentifier("com.adobe.flash.video") { typeID = "com.adobe.flash.video" }
                if attachment.hasItemConformingToTypeIdentifier("com.apple.quicktime-movie") { typeID = "com.apple.quicktime-movie" }
                if attachment.hasItemConformingToTypeIdentifier("public.mpeg-4") { typeID = "public.mpeg-4" }
                if attachment.hasItemConformingToTypeIdentifier("public.mpeg") { typeID = "public.mpeg" }
                if attachment.hasItemConformingToTypeIdentifier("com.microsoft.windows-media-wmv") { typeID = "com.microsoft.windows-media-wmv" }
                
                attachment.loadItem(forTypeIdentifier: typeID, options: nil, completionHandler: { (video, error) in
                    if let shareVideoData = video as? Data {
                        //let title = attachmentFileNameWithoutExt
                        let previewImage = NSImageView()
                        previewImage.frame = CGRect(x: 17 + numberOfPreviews * 52, y: 78, width: 50, height: 50)
                        previewImage.imageFrameStyle = .grayBezel
                        previewImage.image = #imageLiteral(resourceName: "videoLogo.png")
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(previewImage)
                        })
                        let uploadProgressBar = NSProgressIndicator()
                        uploadProgressBar.frame = CGRect(x: 20 + numberOfPreviews * 52, y: 74, width: 44, height: 20)
                        uploadProgressBar.controlSize = .regular
                        uploadProgressBar.isIndeterminate = false
                        uploadProgressBar.doubleValue = 0
                        uploadProgressBar.layer?.zPosition = 1
                        DispatchQueue.main.async(execute: {
                            self.view.addSubview(uploadProgressBar)
                        })
                        
                        
                        numberOfPreviews = numberOfPreviews + 1
                        
                        let uploadVideo = VK.API.Upload.Video.fromFile(Media(videoData: shareVideoData), name: attaсhmentsTitles[numberOfPreviews-1])
                        uploadVideo.progressBlock = {done, total in
                            NotificationCenter.default.addObserver(self, selector: #selector(ShareViewController.userCanceled), name: NSNotification.Name(rawValue: "CancelUpload"), object: nil)
                            if isCanceled == true { uploadVideo.cancel() }
                            DispatchQueue.main.async(execute: {
                                uploadProgressBar.isHidden = false
                                self.sendButton.isEnabled = false
                                uploadProgressBar.maxValue = Double(total)
                                uploadProgressBar.doubleValue = Double(done)
                            })
                        }
                        uploadVideo.successBlock = {response in
                            if uploadVideo.cancelled == false {
                                DispatchQueue.main.async(execute: {
                                    uploadProgressBar.isHidden = true
                                    self.sendButton.isEnabled = true
                                })
                                print(response)
                                attachmentsStrings.append("video" + currentUserID + "_" + String(response["video_id"].intValue))
                            }
                            else {
                                self.deleteItemFromServer(itemString: "video" + currentUserID + "_" + String(response["video_id"].intValue))
                            }
                        }
                        uploadVideo.errorBlock = {error in print("SwiftyVK: uploadVideo fail \n \(error)")}
                        uploadVideo.send()
                    }
                })
            }
        }
    }
    
    //MARK: Отправка
    @IBAction func send(_ sender: AnyObject?) {
        if attachmentsStrings.count > 0 {
            for currentAttachment in 0...attachmentsStrings.count-1 {
                if currentAttachment == 0 {
                    attachmentsFinalString = attachmentsStrings[currentAttachment]
                }
                else {
                    attachmentsFinalString = attachmentsFinalString + "," + attachmentsStrings[currentAttachment]
                }
            }
        }
        
        if self.audienceSwitch.indexOfSelectedItem == 0 {
            let request = VK.API.Wall.post([VK.Arg.friendsOnly : String(self.friendsOnlyCheck.state), VK.Arg.message : (self.commentText.textStorage?.string)!, VK.Arg.attachments : attachmentsFinalString])
            request.send()
            request.successBlock = { response in
                print(response)
                self.closeComposeWindow() }
            
        }
        if self.audienceSwitch.indexOfSelectedItem == 1 {
            let request = VK.API.Wall.post([VK.Arg.ownerId : "-" + groups.IDs[self.toSwitch.indexOfSelectedItem] , VK.Arg.fromGroup : "1", VK.Arg.message : (self.commentText.textStorage?.string)!, VK.Arg.attachments : attachmentsFinalString])
            request.send()
            request.successBlock = { response in self.closeComposeWindow() }
        }
        if self.audienceSwitch.indexOfSelectedItem == 2 {
            if conversations.isConference[self.toSwitch.indexOfSelectedItem] == true {
                let request = VK.API.Messages.send([VK.Arg.attachment : attachmentsFinalString, VK.Arg.message : (self.commentText.textStorage?.string)!, VK.Arg.chatId : conversations.IDs[self.toSwitch.indexOfSelectedItem]])
                request.send()
                request.successBlock = { response in self.closeComposeWindow() }
            }
            if conversations.isConference[self.toSwitch.indexOfSelectedItem] == false {
                let request = VK.API.Messages.send([VK.Arg.attachment : attachmentsFinalString, VK.Arg.message : (self.commentText.textStorage?.string)!, VK.Arg.userId : conversations.IDs[self.toSwitch.indexOfSelectedItem]])
                request.send()
                request.successBlock = { response in self.closeComposeWindow() }
            }
        }
        
    }
    
    @IBAction func cancel(_ sender: AnyObject?) {
        if attachmentsStrings.isEmpty == false {
            for currentAttachment in 0...attachmentsStrings.count-1 { deleteItemFromServer(itemString: attachmentsStrings[currentAttachment]) }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CancelUpload"), object: nil)
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
    @IBAction func audienceSwitchAction(_ sender: Any) {
        if audienceSwitch.indexOfSelectedItem == 0 {
            toSwitch.isHidden = true
            toSwitch.isEnabled = false
            toLabel.isHidden = true
            progressFlower.isHidden = true
            commentLabel.stringValue = "Ваш комментарий"
            friendsOnlyCheck.isHidden = false
        }
        if audienceSwitch.indexOfSelectedItem == 1 {
            toSwitch.isHidden = false
            toSwitch.isEnabled = true
            progressFlower.isHidden = false
            toLabel.isHidden = false
            toLabel.stringValue = "➜"
            commentLabel.stringValue = "Ваш комментарий"
            friendsOnlyCheck.isHidden = true
            toSwitch.removeAllItems()
            toSwitch.addItems(withTitles: groups.names)
        }
        if audienceSwitch.indexOfSelectedItem == 2 {
            toSwitch.isHidden = false
            toSwitch.isEnabled = true
            progressFlower.isHidden = false
            toLabel.isHidden = false
            toLabel.stringValue = "Кому:"
            commentLabel.stringValue = "Сообщение"
            toSwitch.addItems(withTitles: conversations.names)
            friendsOnlyCheck.isHidden = true
            toSwitch.removeAllItems()
            toSwitch.addItems(withTitles: conversations.names)
        }
    }
    
    func grabImageType(typeString : String) -> Media.ImageType
    {
        let ext : Media.ImageType
        switch typeString {
        case "public.jpg":
            ext = .JPG
        case "public.jpeg":
            ext = .JPG
        case "public.png":
            ext = .PNG
        case "com.compuserve.gif":
            ext = .GIF
        default:
            ext = .PNG //unknown
        }
        return ext
    }
    
    func userCanceled() {
        isCanceled = true
    }
    
    func deleteItemFromServer(itemString: String) {
        if itemString.contains("doc") {
            var docString = itemString
            var count = 0
            docString.removeSubrange(docString.startIndex..<docString.index(docString.startIndex, offsetBy: 3))
            for currentCharacter in docString.characters {
                if currentCharacter == "_" {
                    break
                }
                count = count+1
            }
            var ownerID = docString
            var docID = docString
            ownerID.removeSubrange(ownerID.index(ownerID.startIndex, offsetBy: count)..<ownerID.endIndex)
            docID.removeSubrange(docID.startIndex..<docID.index(docID.startIndex, offsetBy: count+1))
            let deleteDoc = VK.API.Docs.delete([VK.Arg.ownerId : ownerID, VK.Arg.docId : docID])
            deleteDoc.send()
        }
        if itemString.contains("audio") {
            var audioString = itemString
            var count = 0
            audioString.removeSubrange(audioString.startIndex..<audioString.index(audioString.startIndex, offsetBy: 5))
            for currentCharacter in audioString.characters {
                if currentCharacter == "_" {
                    break
                }
                count = count+1
            }
            var ownerID = audioString
            var audioID = audioString
            ownerID.removeSubrange(ownerID.index(ownerID.startIndex, offsetBy: count)..<ownerID.endIndex)
            audioID.removeSubrange(audioID.startIndex..<audioID.index(audioID.startIndex, offsetBy: count+1))
            let deleteAudio = VK.API.Audio.delete([VK.Arg.ownerId : ownerID, VK.Arg.audioId : audioID])
            deleteAudio.send()
        }
        if itemString.contains("video") {
            var videoString = itemString
            var count = 0
            videoString.removeSubrange(videoString.startIndex..<videoString.index(videoString.startIndex, offsetBy: 5))
            for currentCharacter in videoString.characters {
                if currentCharacter == "_" {
                    break
                }
                count = count+1
            }
            var ownerID = videoString
            var videoID = videoString
            ownerID.removeSubrange(ownerID.index(ownerID.startIndex, offsetBy: count)..<ownerID.endIndex)
            videoID.removeSubrange(videoID.startIndex..<videoID.index(videoID.startIndex, offsetBy: count+1))
            let deleteVideo = VK.API.Video.delete([VK.Arg.ownerId : ownerID, VK.Arg.videoId : videoID])
            deleteVideo.send()
        }
        if itemString.contains("photo") {
            var photoString = itemString
            var count = 0
            photoString.removeSubrange(photoString.startIndex..<photoString.index(photoString.startIndex, offsetBy: 5))
            for currentCharacter in photoString.characters {
                if currentCharacter == "_" {
                    break
                }
                count = count+1
            }
            var ownerID = photoString
            var photoID = photoString
            ownerID.removeSubrange(ownerID.index(ownerID.startIndex, offsetBy: count)..<ownerID.endIndex)
            photoID.removeSubrange(photoID.startIndex..<photoID.index(photoID.startIndex, offsetBy: count+1))
            let deletePhoto = VK.API.Photos.delete([VK.Arg.ownerId : ownerID, VK.Arg.photoId : photoID])
            deletePhoto.send()
        }
    }
    
    func removeExtensionFromFilename(file: String) -> String {
        var filename = file
        var count = 0
        for currentCharacter in filename.characters.reversed() {
            if currentCharacter == "." {
                break
            }
            count = count + 1
        }
        filename.removeSubrange(filename.index(filename.endIndex, offsetBy: -count-1)..<filename.endIndex)
        return filename
    }
    
    
    
    
    
    
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var commentLabel: NSTextField!
    @IBOutlet weak var toLabel: NSTextField!
    @IBOutlet weak var progressFlower: NSProgressIndicator!
    @IBOutlet weak var toSwitch: NSPopUpButton!
    @IBOutlet weak var audienceSwitch: NSPopUpButton!
    @IBOutlet weak var currentUserLabel: NSTextField!
    @IBOutlet weak var friendsOnlyCheck: NSButton!
    @IBOutlet var commentText: NSTextView!
    
    
}
