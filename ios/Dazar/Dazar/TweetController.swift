//
//  TweetController.swift
//  Dazar
//
//  Created by Alex Shacked on 14/12/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit


protocol TweetControllerDelegate: class {
    func tweetControllerDidCancel(controller: TweetController)
    func tweetControllerDidOk(controller: TweetController, newTweet tweet: String)
}

class TweetController: UITableViewController, UITextFieldDelegate {
    weak var delegate: TweetControllerDelegate?
    @IBOutlet weak var message: UITextView!
    var utils = Utils()
    
    @IBAction func cancel(sender: AnyObject) {
        delegate?.tweetControllerDidCancel(self)
    }
    
    @IBAction func done(sender: AnyObject) {
        if message.text.isEmpty == true {
            utils.displayAlertWithTitle(self, title: "Tweet message missing",
                message: "Please enter a text message or press the Cancel button.")
        } else {
            delegate?.tweetControllerDidOk(self, newTweet:  message.text)
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
}









