//
//  addTweetTableViewController.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 4/1/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

class addTweetTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var tweetText: UITextView!
    @IBOutlet weak var charCount: UILabel!
    //var addTweetDelegate : AddTweetDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Tweet"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: "cancel:")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Done,
            target: self,
            action: "done:")
        
        tweetText.delegate = self
    }
    
    func cancel(sender : AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done(sender : AnyObject){
        if(tweetText.text.characters.count <= 140){
            addTweet()
            self.dismissViewControllerAnimated(true, completion:nil)
        }else{
            let alertController = UIAlertController(
                title: "Can't Post!",
                message: "Your tweet is too long. It must be 140 characters or less!",
                preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tweetText.becomeFirstResponder()
    }
    

    func textViewDidChange(textView: UITextView) {
        let charNum = tweetText.text.characters.count
        charCount.text = "\(charNum)/140"
        
        if charNum > 140 {
            charCount.textColor = UIColor.redColor()
        } else {
            charCount.textColor = UIColor.blackColor()
        }
        
    }

    
    func addTweet() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let urlString = kBaseURLString + "/add-tweet.cgi"
        let parameters = [
            "username" : appDelegate.username,  // username and password
            "session_token" : SSKeychain.passwordForService(kTwitterPassService, account: appDelegate.username!+"token"),  // obtained from user
            "tweet" : tweetText.text
        ]
        
        request(.POST, urlString, parameters: parameters)
            .responseJSON { response in
                switch(response.result){
                case .Success( _):
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: kAddTweetNotification, object: nil))
                case .Failure(let error):
                    let message : String
                    if let httpStatusCode = response.response?.statusCode {
                        switch(httpStatusCode) {
                        case 500:
                            message = "Internal Server Error: something wrong on our side"
                        case 400:
                            message = "All parameters not provided"
                        case 401:
                            message = "Unauthorized!"
                        case 404:
                            message = "No such user!"
                        default:
                            message = "Error \(httpStatusCode)"
                        }
                    } else {  // probably network or server timeout
                        message = error.localizedDescription
                    }
                    
                    let alertController = UIAlertController(
                        title: "Error Fetching Items",
                        message: message,
                        preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
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
