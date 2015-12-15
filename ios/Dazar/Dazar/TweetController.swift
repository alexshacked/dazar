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
    
    @IBAction func cancel(sender: AnyObject) {
        delegate?.tweetControllerDidCancel(self)
    }
    
    @IBAction func done(sender: AnyObject) {
        if message.text.isEmpty == true {
            displayAlertWithTitle("Tweet message missing",
                message: "Please enter a text message or press the Cancel button.")
        } else {
            delegate?.tweetControllerDidOk(self, newTweet:  message.text)
        }
    }
    
    func displayAlertWithTitle(title: String, message: String){
        let controller = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        controller.addAction(action)
        
        presentViewController(controller, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
}









