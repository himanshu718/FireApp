//
//  TimeHelper.swift
//  FireApp
//
//  Created by Devlomi on 7/30/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class TimeHelper {
    private static let minute = 60
    private static let hour = 60 * minute
    private static let day = 24 * hour
    private static let week = 7 * day
    private static let SEPARATOR = " ";

    public static func getMediaTime(timestamp: Date) -> String {
        let secondsAgo = Int(Date().timeIntervalSince(timestamp))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"

        let timedFormat = dateFormatter.string(from: timestamp)



        if secondsAgo < minute {
            return Strings.just_now
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute) \(Strings.minutes_ago)"
        } else if secondsAgo < day {
            let hoursAgo = (secondsAgo / hour);
            if (hoursAgo <= 5) {
                return "\(hoursAgo) \(Strings.hours_ago)"
            }

            return "\(Strings.today) ,\(timedFormat) "
        } else if secondsAgo < week {
            return "\(secondsAgo / day) \(Strings.days_ago)"
        }

        return "\(secondsAgo / week) \(Strings.weeks_ago)"
    }
    public static func getTimeOnly(date: Date) -> String {



        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"


        let newDate = dateFormatter.string(from: date)


        return newDate
    }

    //this will format time and get when the user was last seen
    public static func getTimeAgo(timestamp: Date) -> String {
        let fullDateFormat = DateFormatter(formatType: "yyyy/MM/dd")
        let timeFormat = DateFormatter(formatType: "hh:mm a")


        let secondsAgo = Int(Date().timeIntervalSince(timestamp))





        if (secondsAgo < minute) {
            return "" /* now */
        }
        else if (secondsAgo < hour) {
            //minutes ago
            return "\(secondsAgo / minute)\(SEPARATOR) \(Strings.minutes_ago)"
        }
        else if secondsAgo < day {
            //hours ago
            let hoursAgo = (Int)(secondsAgo / hour)
            if (hoursAgo <= 5) {
                return "\(hoursAgo)\(SEPARATOR)\(Strings.hours_ago)"
            }
            //today at + time AM or PM
            return "\(Strings.today_at)\(SEPARATOR) \(timeFormat.string(from: timestamp))"
        } else if (secondsAgo < week) {
            let daysAgo = (Int) (secondsAgo / day);
            //yesterday + time AM or PM
            if (daysAgo == 1) {
                return "\(Strings.yesterday_at)\(SEPARATOR)\(timeFormat.string(from: timestamp))";
            }
            //days ago
            return "\(secondsAgo / day)\(SEPARATOR) \(Strings.days_ago)";
        }

        //otherwise it's been a long time show the full date

        return "\(fullDateFormat.string(from: timestamp))\(SEPARATOR) \(Strings.at)\(SEPARATOR)\(timeFormat.string(from: timestamp))";
    }

    public static func getDate(timestamp: Date) -> String {
        let fullDateFormat = DateFormatter(formatType: "yyyy/MM/dd")
        return fullDateFormat.string(from: timestamp)
    }

    public static func isSameDay(timestamp: Date, oldTimestamp: Date) -> Bool {
        return Calendar.current.isDate(timestamp, inSameDayAs: oldTimestamp)
    }

    public static func isYesterday(timestamp: Date) -> Bool {
        return Calendar.current.isDateInYesterday(timestamp)
    }

    public static func isSameYear(timestamp: Date) -> Bool {
        return Calendar.current.isDate(Date(), equalTo: timestamp, toGranularity: .year)

    }
    public static func getTimeBefore24Hours() -> Int64 {

        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!.currentTimeMillis()

    }

    public static func getStatusTime(timestamp: Date) -> String {
        let secondsAgo = Int(Date().timeIntervalSince(timestamp))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"

        let timedFormat = dateFormatter.string(from: timestamp)



        if secondsAgo < minute {
            return Strings.just_now
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute) \(Strings.minutes_ago)"
        } else if secondsAgo < day {
            let hoursAgo = (secondsAgo / hour);
            if (hoursAgo <= 5) {
                return "\(hoursAgo) \(Strings.hours_ago)"
            }

            return "\(Strings.today),\(timedFormat) "
        }
        let now = Date()

        if isSameDay(timestamp: now, oldTimestamp: timestamp) {
            return "\(Strings.today) , " + timedFormat
        }

        return "\(Strings.yesterday_at) " + timedFormat
    }

    public static func getCallTime(timestamp: Date) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"

        let timedFormat = dateFormatter.string(from: timestamp)

        let simpleFormatter = DateFormatter()//eg: October 9, 6:10PM
        simpleFormatter.dateFormat = "MMMM dd hh:mm a"

        let simpleFormat = simpleFormatter.string(from: timestamp)


        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy/MM/dd, hh:mm a"

        let fullDateFormat = fullDateFormatter.string(from: timestamp)


        if isSameDay(timestamp: Date(), oldTimestamp: timestamp) {
            return "\(Strings.today), \(timedFormat)"
        }

        if isYesterday(timestamp: timestamp) {
            return "\(Strings.yesterday), \(timedFormat)"
        }

        if isSameYear(timestamp: timestamp) {
            return simpleFormat
        }

        return fullDateFormat


    }
    public static func getChatTime(timestamp: Date) -> String {

        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "yyyy/MM/dd"

        let fullDateFormat = fullDateFormatter.string(from: timestamp)


        if isSameDay(timestamp: Date(), oldTimestamp: timestamp) {
            return Strings.today.uppercased()
        }

        if isYesterday(timestamp: timestamp) {
            return Strings.yesterday.uppercased()
        }



        return fullDateFormat



    }
    public static func isMessageTimePassed(serverTime: Date, messageTime: Date) -> Bool {
        let expiredMessageTime: TimeInterval = 15 * 60
        let isExpired = serverTime.timeIntervalSince(messageTime) >= expiredMessageTime
        return isExpired
    }
    
    //this method will check if message time has passed , if the user wants to delete the message for everyone
    public static func isTimePassedBySeconds( biggerTime:Double,  smallerTime:Double, seconds:Int) -> Bool {
        let elapsedMillis = biggerTime - smallerTime;
        let secondsPassed = elapsedMillis / 1000;
        return Int(secondsPassed) >= seconds;
    }

    
    public static func isCallTimePassed(serverTime: Date, messageTime: Date) -> Bool {
          let expiredMessageTime: TimeInterval = 15 * 60
          let isExpired = serverTime.timeIntervalSince(messageTime) >= expiredMessageTime
          return isExpired
      }
    
    public static func canRequestUnDeliveredNotifications(lastRequestTime:Date) -> Bool {
           let allowedTime: TimeInterval = 10 //10 sec
           return Date().timeIntervalSince(lastRequestTime) >= allowedTime
       }
    

    public static func shouldFetchStatuses(lastSyncTime: Date) -> Bool {
        let timeToWait: TimeInterval = 15 //15 sec
        let shouldFetch = Date().timeIntervalSince(lastSyncTime) > timeToWait
        return shouldFetch
    }

    public static func getMessageTime(date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"

        let timeFormat = timeFormatter.string(from: date)

        return timeFormat
    }
    
    public static func getDateAndTime(date: Date) -> String {
          let timeFormatter = DateFormatter()
          timeFormatter.dateFormat = "yyyy/MM/dd hh:mm a"

          let timeFormat = timeFormatter.string(from: date)

          return timeFormat
      }


}


