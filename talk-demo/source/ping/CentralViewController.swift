//
//  CentralViewController.swift
//  talk-demo
//
//  Created by Benjamin Deming on 10/25/15.
//  Copyright © 2015 Benjamin Deming. All rights reserved.
//

import UIKit

class CentralViewController: UIViewController {
    var central = Central()
    
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Central"
        
        label.text = textForState(central.currentState)
        central.currentStateChangedHandler = { [unowned self] (state: Central.State) -> Void in
            let text = self.textForState(state)
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.label.text = text
            })
        }
    }
    
    func textForState(state: Central.State) -> String {
        switch state {
        case .Idle:
            return "Not scanning for peripherals that support the ping service."
        case .Scanning:
            return "Scanning for peripherals with the ping service."
        case .HeardPing():
            return "Received ping from peripheral"
        }
    }
}