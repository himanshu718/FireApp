//
//  Ringtones.swift
//  FireApp
//
//  Created by Devlomi on 11/17/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class Ringtones {
    private static let m4r = ".m4r"
    private static let caf = ".caf"

    public static var ringtones: [String: String] {
        get {
            var mRingtones = [String: String]()

            mRingtones["Keys"] = "keys" + m4r
            mRingtones["Note"] = "note" + m4r
            mRingtones["Incoming"] = "incomingshort" + caf
            mRingtones["Tri-Tone"] = "Tri-tone" + caf
            mRingtones["Popcorn"] = "popcorn" + m4r
            mRingtones["Complete"] = "complete" + m4r
            mRingtones["Beacon"] = "Beacon" + m4r
            mRingtones["Circles"] = "circles" + m4r
            mRingtones["TimePassing"] = "TimePassing" + caf
            mRingtones["Aurora"] = "aurora" + m4r
            mRingtones["Bell"] = "Bell" + caf
            mRingtones["Synth"] = "synth" + m4r
            mRingtones["Hello"] = "hello" + m4r
            mRingtones["Chord"] = "chord" + m4r
            mRingtones["Opening"] = "Opening" + m4r
            mRingtones["Harp"] = "Harp" + caf
            mRingtones["Pulse"] = "pulse" + m4r
            mRingtones["Glass"] = "Glass" + caf
            mRingtones["Boing"] = "Boing" + caf
            mRingtones["Bamboo"] = "bamboo" + m4r
            mRingtones["Xylophone"] = "Xylophone" + caf
            mRingtones["Apex"] = "Apex" + m4r
            mRingtones["Input"] = "input" + m4r

            
            


            return mRingtones
        }
        set{
            
        }
         


    }
}
