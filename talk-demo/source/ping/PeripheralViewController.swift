//
//  PeripheralViewController.swift
//  talk-demo
//
//  Created by Benjamin Deming on 10/25/15.
//  Copyright © 2015 Benjamin Deming. All rights reserved.
//

import UIKit

class PeripheralViewController: UIViewController {
    var peripheral = Peripheral()
    
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Peripheral"
        
        peripheral.currentStateChangedHandler = { [unowned self] (state: Peripheral.State) -> Void in
            var text = ""
            switch state {
            case .Idle:
                text = "Not ready to advertise."
            case .Advertising:
                text = "Advertising."
            case .Acknowledged(let rtt):
                text = String(format: "Round trip time:\n%.f msec", rtt * 1000)
            }
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.label.text = text
            })
        }
    }
} 