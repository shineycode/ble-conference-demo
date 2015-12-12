//
//  Message.swift
//  talk-demo
//
//  Created by Benjamin Deming on 10/25/15.
//  Copyright © 2015 Benjamin Deming. All rights reserved.
//

import Foundation

/**
 An enum that can represent two types of messages: a PING and an acknowledgement (ACK).
 It has some boilerplate to transform to and from NSData representations.
*/
enum Message: String, RawRepresentable {
    typealias RawValue = NSData
    
    case PING
    case ACK
    
    var stringRepresentation: String {
        get {
            switch self {
            case .PING:
                return "PING"
            case .ACK:
                return "ACK"
            }
        }
    }
    
    var rawValue: RawValue {
        get {
            return stringRepresentation.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData()
        }
    }
    
    init?(rawValue: RawValue) {
        let string = NSString(data: rawValue, encoding: NSUTF8StringEncoding)
        
        if string == Message.PING.stringRepresentation {
            self = .PING
        } else if string == Message.ACK.stringRepresentation {
            self = .ACK
        } else {
            return nil
        }
    }
}