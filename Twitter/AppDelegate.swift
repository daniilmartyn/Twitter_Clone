//
//  AppDelegate.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 3/30/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

let kAddTweetNotification = "kAddTweetNotification"
let kTwitterPassService = "WSUVTwitterPassword"
//let kBaseURLString = "https://bend.encs.vancouver.wsu.edu/~wcochran/cgi-bin"
let kBaseURLString = "https://ezekiel.encs.vancouver.wsu.edu/~cs458/cgi-bin"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var tweets = [Tweet]()
    var loggedin : Bool = false
    
    var username : String?
    
    func lastTweetDate() -> NSDate{
        
        if tweets.count == 0 {
            return NSDate.distantPast()
        } else {
            return tweets.first!.date
        }
    }
    
    func archivePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true)
        
        let sandBoxDir : NSString = paths[0]
        let archiveName = sandBoxDir.stringByAppendingPathComponent("tweets.plist")
        return archiveName
    }
    
    func archivePathUser() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true)
        
        let sandBoxDir : NSString = paths[0]
        let archiveName = sandBoxDir.stringByAppendingPathComponent("user.plist")
        return archiveName
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        let archiveName = archivePath()
        if(NSFileManager.defaultManager().fileExistsAtPath(archiveName)){
            
            NSLog("Archive already exists")
            let archive = NSArray(contentsOfFile: archiveName)
            
            for index in archive! {
                let tweet = index as! [String:AnyObject]
                
                tweets.append(Tweet(
                    id: tweet["tweet_id"] as! Int,
                    name: tweet["username"] as! String,
                    del: tweet["isDeleted"] as! Bool,
                    twt: tweet["tweet"] as! String,
                    dat: tweet["date"] as! NSDate))
            }
        }else{
            NSLog("no tweet archive, do things as normal")
        }
        
        let userArchive = archivePathUser()
        if(NSFileManager.defaultManager().fileExistsAtPath(userArchive)){
            NSLog("restoring logged in info")
            let archive = NSDictionary(contentsOfFile: userArchive)
            username = archive!["username"] as? String
            loggedin = archive!["loggedin"] as! Bool
            
            NSLog("username now is: \(username) and status is \(loggedin)")
            
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let archiveName = archivePath()
        
        var list : [[String:AnyObject]] = []
        
        
        for tweet in tweets {
            let tweet_dict = [
                "tweet_id" : tweet.tweet_id,
                "username" : tweet.username,
                "isDeleted" : tweet.isDeleted,
                "tweet" : tweet.tweet,
                "date" : tweet.date
            ]
            list.append(tweet_dict)
        }
        
        let archive = list as NSArray
        archive.writeToFile(archiveName, atomically: true)
        
        
        
        let userPathArchive = archivePathUser()
        let userDict : [String: AnyObject] = [
            "username" : username!,
            "loggedin" : loggedin
        ]
    
        let archiveUser = userDict as NSDictionary
        archiveUser.writeToFile(userPathArchive, atomically: true)
        NSLog("wrote the archive")
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

