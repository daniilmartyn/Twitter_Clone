//
//  twitterTableViewController.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 4/1/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

class twitterTableViewController: UITableViewController {

    
    @IBOutlet weak var addTweetButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // XXX NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        self.title = "Tweets!"
        
        if(appDelegate.loggedin){
            addTweetButton.enabled = true
        }else {
            addTweetButton.enabled = false
        }
        
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !self.refreshControl!.refreshing {
            self.refreshControl!.beginRefreshing()
            self.tweetsRefresh(self)
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
        
        
        NSLog("Latest stored tweet: \(lastTweetDate)")
        // If successfully fetched new tweets
        
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
                        
                        
                        if !del {
                            let tweet = Tweet(id: tweetID, name: name, del: del, twt: twt, dat: date!)
                            appDelegate.tweets.insert(tweet, atIndex: 0)
                        } else {
                            for tweet in appDelegate.tweets {
                                if tweet.tweet_id == tweetID {
                                    appDelegate.tweets.removeAtIndex(appDelegate.tweets.indexOf(tweet)!)
                                }
                            }
                        }
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if appDelegate.loggedin {
            let alertController = UIAlertController(
                title: "Manage Account",
                message: nil,
                preferredStyle: .ActionSheet)
            
            alertController.addAction(UIAlertAction(
                title: "Cancel",
                style: .Cancel,
                handler: nil))
            alertController.addAction(UIAlertAction(
                title: "Logout",
                style: .Default,
                handler: {(UIAlertAction) -> Void in
                    self.logout()}))
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let popoverPresenter = alertController.popoverPresentationController
                popoverPresenter?.barButtonItem = sender as? UIBarButtonItem
            }
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(
                title: "Manage Account",
                message: nil,
                preferredStyle: .ActionSheet)
            
            alertController.addAction(UIAlertAction(
                title: "Cancel",
                style: .Cancel,
                handler: nil))
            alertController.addAction(UIAlertAction(
                title: "Register",
                style: .Default,
                handler: {(UIAlertAction) -> Void in
                    self.registerAlert()}))
            alertController.addAction(UIAlertAction(
                title: "Login",
                style: .Default,
                handler: {(UIAlertAction) -> Void in
                    self.loginAlert()}))
            
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let popoverPresenter = alertController.popoverPresentationController
                popoverPresenter?.barButtonItem = sender as? UIBarButtonItem
            }
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func addTweet(sender: AnyObject) {
        
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("addTweetNavController")
            controller?.modalPresentationStyle = .Popover
            presentViewController(controller!, animated: true, completion: nil)

    }
    
    
    
    func loginAlert(){
        let alertController = UIAlertController(title: "Login", message: "Please Log In", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Login", style: .Default, handler: { _ in
            let usernameTextField = alertController.textFields![0]
            let passwordTextField = alertController.textFields![1]
            
            let username = usernameTextField.text!
            let password = passwordTextField.text!
            
            if username.isEmpty || password.isEmpty {
                let alert = UIAlertController(
                    title: "Empty!",
                    message: "The username or password field is not filled",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {_ in
                    self.loginAlert()
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }else {
                self.login(username, password: password)
            }
            
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.addTextFieldWithConfigurationHandler{ (textField : UITextField) -> Void in
            textField.placeholder = "Username"
        }
        alertController.addTextFieldWithConfigurationHandler{ (textField : UITextField) -> Void in
            textField.secureTextEntry = true
            textField.placeholder = "Password"
        }
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func login(username : String, password : String){
        //NSLog("loging in User with username: \(username) and password \(password)")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let urlString = kBaseURLString + "/login.cgi"
        let parameters = [
            "username" : username,  // username and password
            "password" : password,  // obtained from user
            "action" : "login"
        ]
        
        request(.POST, urlString, parameters: parameters)
            .responseJSON { response in
                switch(response.result){
                case .Success(let JSON):
                    let dict = JSON as! [String: AnyObject]
                    let token = dict["session_token"] as! String
                    
                    appDelegate.username = username
                    SSKeychain.setPassword(password, forService: kTwitterPassService, account: username)
                    SSKeychain.setPassword(token, forService: kTwitterPassService, account: username+"token")
                    appDelegate.loggedin = true
                    self.addTweetButton.enabled = true
                    self.title = "Tweets! (\(username))"
                case .Failure(let error):
                    let message : String
                    if let httpStatusCode = response.response?.statusCode {
                        switch(httpStatusCode) {
                        case 500:
                            message = "Internal Server Error: something wrong on our side"
                        case 400:
                            message = "Both username and password not provided!"
                        case 401:
                            message = "Wrong Password!"
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
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                        self.loginAlert()}))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            }

    }
    
    func logout(){
        NSLog("Logout now")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let urlString = kBaseURLString + "/login.cgi"
        let parameters = [
            "username" : appDelegate.username,  // username and password
            "password" : SSKeychain.passwordForService(kTwitterPassService, account: appDelegate.username),  // obtained from keychain
            "action" : "logout"
        ]
        
        request(.POST, urlString, parameters: parameters)
            .responseJSON { response in
                switch(response.result){
                case .Success(let JSON):
                    let dict = JSON as! [String: AnyObject]
                    let token = dict["session_token"] as! String
                    
                    SSKeychain.setPassword(token, forService: kTwitterPassService, account: appDelegate.username!+"token")
                    appDelegate.loggedin = false
                    appDelegate.username = ""
                    self.addTweetButton.enabled = false
                    self.title = "Tweets!"
                case .Failure(let error):
                    let message : String
                    if let httpStatusCode = response.response?.statusCode {
                        switch(httpStatusCode) {
                        case 500:
                            message = "Internal Server Error: something wrong on our side"
                        case 400:
                            message = "Both username and password not provided!"
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
    
    func registerAlert(){
        let alertController = UIAlertController(title: "Register", message: "Create Username and Password", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Submit", style: .Default, handler: { _ in
            let usernameTextField = alertController.textFields![0]
            let passwordTextField = alertController.textFields![1]
            let confirmTextField = alertController.textFields![2]
            
            let username = usernameTextField.text!
            let password = passwordTextField.text!
            let confirm = confirmTextField.text!
            
            if username.characters.count < 3 {
                let alert = UIAlertController(
                    title: "Invalid Username!",
                    message: "Username must be at least 3 characters long",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                    self.registerAlert()}))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            if password.characters.count < 8 || (password != confirm) {
                let alert = UIAlertController(
                    title: "Bogus Password",
                    message: "Password too short or not confirmed!",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                    self.registerAlert()}))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            self.register(username, password: password)
            
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.addTextFieldWithConfigurationHandler{ (textField : UITextField) -> Void in
            textField.placeholder = "Username"
        }
        alertController.addTextFieldWithConfigurationHandler{ (textField : UITextField) -> Void in
            textField.secureTextEntry = true
            textField.placeholder = "Password"
        }
        alertController.addTextFieldWithConfigurationHandler{ (textField: UITextField) -> Void in
            textField.secureTextEntry = true
            textField.placeholder = "Confirm"
        }
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func register(username : String, password : String){
        NSLog("Registering the User now")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let urlString = kBaseURLString + "/register.cgi"
        let parameters = [
            "username" : username,  // username and password
            "password" : password,  // obtained from user
        ]
        
        request(.POST, urlString, parameters: parameters)
            .responseJSON { response in
                switch(response.result){
                case .Success(let JSON):
                    let dict = JSON as! [String: AnyObject]
                    let token = dict["session_token"] as! String
                    
                    appDelegate.username = username
                    SSKeychain.setPassword(password, forService: kTwitterPassService, account: username)
                    SSKeychain.setPassword(token, forService: kTwitterPassService, account: username+"token")
                    appDelegate.loggedin = true
                    self.addTweetButton.enabled = true
                    self.title = "Tweets! (\(username))"
                case .Failure(let error):
                    let message : String
                    if let httpStatusCode = response.response?.statusCode {
                        switch(httpStatusCode) {
                        case 500:
                            message = "Internal Server Error: something wrong on our side"
                        case 400:
                            message = "Both username and password not provided!"
                        case 409:
                            message = "Username already exists!"
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
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let deleteTweet = appDelegate.tweets[indexPath.row]
        
        if (deleteTweet.username == appDelegate.username ){
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            let deleteTweet = appDelegate.tweets[indexPath.row]
            
            let urlString = kBaseURLString + "/del-tweet.cgi"
            let parameters : [String:AnyObject] = [
                "username" : appDelegate.username!,
                "session_token" : SSKeychain.passwordForService(kTwitterPassService, account: appDelegate.username!+"token"),
                "tweet_id" : deleteTweet.tweet_id
            ]
            
            
            
            request(.POST, urlString, parameters: parameters)
                .responseJSON { response in
                    switch(response.result){
                    case .Success(_):
                        //let dict = JSON as! [String: AnyObject]
                        appDelegate.tweets.removeAtIndex(appDelegate.tweets.indexOf(deleteTweet)!)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    case .Failure(let error):
                        let message : String
                        if let httpStatusCode = response.response?.statusCode {
                            switch(httpStatusCode) {
                            case 500:
                                message = "Internal Server Error: something wrong on our side"
                            case 400:
                                message = "All parameters not provided!"
                            case 401:
                                message = "Unauthorized!"
                            case 403:
                                message = "Not the user's tweet!"
                            case 404:
                                message = "No such user or no tweet found!"
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
