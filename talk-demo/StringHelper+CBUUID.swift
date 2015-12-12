//
//  StringHelper+CBUUID.swift 
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

extension String {
    static func convertToCBUUID(serviceUUID: String?) -> CBUUID? {
        if let uuid = serviceUUID {
            if uuid.characters.count > 0 {
                return CBUUID(string: uuid)
            }
        }
        
        return nil
    }
}