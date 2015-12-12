//
//  ListenerTableViewDataSource.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

class ListenerTableViewDataSource {
    var countOfRows: Int  {
        return rows.count
    }
    
    private var rows = [String]()
    
    func addItem(identifier: String) {
        if !rows.contains(identifier) {
            rows.append(identifier)
        }
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> String {
        precondition(indexPath.row < rows.count && rows.count > 0, "Row exceeds size of data source contents")
        return rows[indexPath.row]
    }
    
    func clear() {
        rows.removeAll()
    }    
}