//
//  ViewController.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import UIKit

class ViewController : UIViewController {
    
    @IBAction func onCentralModeButtonPressed(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Central", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("ListenerViewController") as UIViewController
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func onPeripheralModeButtonPressed(sender: AnyObject) {
        
    }
}