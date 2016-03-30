//
//  Tweet.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 3/30/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import Foundation

class Tweet {
    var tweet_id : Int
    var username : String
    var isDeleted : Bool
    var tweet : String
    var date : NSDate
    
    init(id : Int, name : String, twt : String, dat : NSDate){
        tweet_id = id
        username = name
        isDeleted = false
        tweet = twt
        date = dat
    }
}