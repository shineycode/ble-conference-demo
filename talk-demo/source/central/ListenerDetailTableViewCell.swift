//
//  ListenerDetailTableViewCell.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import UIKit

class ListenerDetailTableViewCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var characteristicPropertyLabel: UILabel!
    
    var rowData: TableRow? = nil {
        didSet {
            if let data = rowData {
                titleLabel.text = data.title
                valueLabel.text = data.content
                characteristicPropertyLabel.text = data.accessoryText
            } else {
                titleLabel.text = "Unknown data"
                valueLabel.text = ""
                characteristicPropertyLabel.text = ""
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        characteristicPropertyLabel.layer.borderColor = UIColor.greenColor().CGColor
        characteristicPropertyLabel.layer.borderWidth = 1.0
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}