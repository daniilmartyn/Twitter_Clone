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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        self.dismissViewControllerAnimated(true, completion: nil)
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

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
