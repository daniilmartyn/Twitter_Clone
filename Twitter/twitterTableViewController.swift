//
//  twitterTableViewController.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 4/1/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

class twitterTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        self.title = "Tweets!"
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            kAddTweetNotification,
            object: nil,
            queue: nil) { (note : NSNotification) -> Void in
                if !self.refreshControl!.refreshing {
                    self.refreshControl!.beginRefreshing()
                    self.tweetsRefresh(self)
                }
                
            }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func fetchTweets(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(abbreviation: "PST")
        let lastTweetDate = appDelegate.lastTweetDate() // get date of latest stored tweet
        let dateStr = dateFormatter.stringFromDate(lastTweetDate)
        
        // If successfully fetched new tweets
        
        //let kBaseURLString = "https://bend.encs.vancouver.wsu.edu/~wcochran/cgi-bin"
        let kBaseURLString = "https://ezekiel.encs.vancouver.wsu.edu/~cs458/cgi-bin"
        
        
        request(.GET, kBaseURLString + "/get-tweets.cgi", parameters: ["date" : dateStr])
            .validate(statusCode : 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON{ response in
                switch(response.result){
                case .Success(let JSON):        // successfuly fetched tweets
                    let dict = JSON as! [String : AnyObject]
                    let tweets = dict["tweets"] as! [[String: AnyObject]]
                    
                    for i in 0 ..< tweets.count {
                        let info = tweets[i]
                        let date = dateFormatter.dateFromString(info["time_stamp"] as! String)
                        
                        let tweetID = info["tweet_id"] as! Int
                        let name = info["username"] as! String
                        let del = info["isdeleted"] as! Bool
                        let twt = info["tweet"] as! String

                        //let tempid = Int64(i)
                        
                        let tweet = Tweet(id: tweetID, name: name, del: del, twt: twt, dat: date!)
                        
                        appDelegate.tweets.insert(tweet, atIndex: 0)
                    }
                    
                    
                    self.tableView.reloadData()
                case .Failure(let error):
                    let message : String
                    if let httpStatusCode = response.response?.statusCode {
                        switch(httpStatusCode) {
                        case 500:
                            message = "Internal Server Error: something wrong on our side"
                        case 503:
                            message = "Database Unavailable: unable to connect"
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
        
        
        self.refreshControl?.endRefreshing()
    }
    
    
    
    @IBAction func tweetsRefresh(sender: AnyObject) {
        NSLog("fetching tweets!")
        fetchTweets()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let tweets = appDelegate.tweets
        return tweets.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tweetCell", forIndexPath: indexPath)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let tweets = appDelegate.tweets
        let tweet = tweets[indexPath.row]

        cell.textLabel?.numberOfLines = 0   // multi-line label
        cell.textLabel?.attributedText = attributedStringForTweet(tweet)
        
        return cell
    }
    
    lazy var tweetDateFormatter : NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()
    
    let tweetTitleAtributes = [
        NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
        NSForegroundColorAttributeName : UIColor.purpleColor()
    ]
    
    lazy var tweetBodyAttributes : [String : AnyObject] = {
        let textStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        textStyle.lineBreakMode = .ByWordWrapping
        textStyle.alignment = .Left
        let bodyAttributes = [
            NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSForegroundColorAttributeName : UIColor.blackColor(),
            NSParagraphStyleAttributeName : textStyle
        ]
        return bodyAttributes
    }()
    
    var tweetAttributedStringMap : [Tweet : NSAttributedString] = [:]
    
    func attributedStringForTweet(tweet : Tweet) -> NSAttributedString {
        let attrbutedString = tweetAttributedStringMap[tweet]
        if let string = attrbutedString { // already stored?
            return string
        }
        
        let dateString = tweetDateFormatter.stringFromDate(tweet.date)
        let title = String(format: "%@ - %@\n", tweet.username, dateString)
        
        let tweetAttributedString = NSMutableAttributedString(string: title, attributes: tweetTitleAtributes)
        let bodyAttributedString = NSAttributedString(string: tweet.tweet, attributes: tweetBodyAttributes)
        
        tweetAttributedString.appendAttributedString(bodyAttributedString)
        tweetAttributedStringMap[tweet] = tweetAttributedString
        return tweetAttributedString
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    @IBAction func manageAccount(sender: AnyObject) {
        
        NSLog("Open Up Menu for account stuff")
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
