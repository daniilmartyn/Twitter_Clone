//
//  Tweet.swift
//  Twitter
//
//  Created by Daniil Sergeyevich Martyn on 3/30/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import Foundation

class Tweet: Hashable {
    var tweet_id : Int
    var username : String
    var isDeleted : Bool
    var tweet : String
    var date : NSDate
    
    var hashValue: Int {
        return tweet_id
    }
    
    init(id : Int, name : String, twt : String, dat : NSDate){
        tweet_id = id
        username = name
        isDeleted = false
        tweet = twt
        date = dat
    }
}

func ==(lhs: Tweet, rhs: Tweet) -> Bool {
    return lhs.tweet_id == rhs.tweet_id
}