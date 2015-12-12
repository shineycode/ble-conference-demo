//
//  ArrayHelper+CBUUID.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

internal func createCBUUIDArray(array: Array<String>?) -> Array<CBUUID>? {
    var convertedArray: Array<CBUUID>? = nil
    
    if let UUIDs = array {
        let filtered = UUIDs.filter{ (element) in element.characters.count >  0 }
        
        if filtered.count > 0 {
            convertedArray = filtered.map { CBUUID(string: $0) }
        }
    }
    
    return convertedArray
}

extension CBUUID {
    // Convert UUID to array form
    static func createArrayFromUUID(uuid: CBUUID?) -> Array<CBUUID>? {
        var result: Array<CBUUID>?
        
        guard let identifier = uuid else {
            return nil
        }
        
        result = Array<CBUUID>()
        result?.append(identifier)

        return result
    }
}