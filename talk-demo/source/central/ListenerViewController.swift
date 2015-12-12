//
//  ListenerViewController.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import UIKit
import CoreBluetooth

class ListenerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SimpleCentralDelegate {
    // MARK: Outlets
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var serviceIDTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
   
    private var isScanning: Bool = false
    
    var simpleCentral: SimpleCentral! // Doing this in order to make this view controller a SimpleCentralDelegate

    // MARK: Data and data source
    
    // Using a lazy stored property to avoid declaring this property as an optional or an implictly
    // unwrapped optional. The downside is that your instance does not get created until accessed.
    // See: http://blog.scottlogic.com/2014/11/20/swift-initialisation.html
    lazy private var dataSource: ListenerTableViewDataSource = {
        return ListenerTableViewDataSource()
    }()
    
    var selectedPeripheralData: PeripheralData?
    var peripheralStore = PeripheralStore()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        simpleCentral = SimpleCentral(delegate: self)
    }
}

extension ListenerViewController {
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(animated: Bool) {
        toggleScanMode(startScanning: true)
        
        // Become SimpleCentral's delegate whenever we're visible
        simpleCentral.delegate = self
        
        super.viewWillAppear(animated)
    }
}

extension ListenerViewController {
    @IBAction func startScanButton(sender: UIButton) {
        if !isScanning {
            clearDataSource()
            toggleScanMode(startScanning: true)
        } else {
            toggleScanMode(startScanning: false)
        }
    }
}

// MARK: UITableViewDataSource/UITableViewDelegate methods
extension ListenerViewController {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.countOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        if let peripheralProfile = peripheralAtIndexPath(indexPath) {
            cell.textLabel?.text = peripheralProfile.displayName
        } else {
           cell.textLabel?.text = "Unknown peripheral"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // Save the selected PeripheralProfile so the segue can be prepared
        selectedPeripheralData = peripheralAtIndexPath(indexPath)
        
        performSegueWithIdentifier("ListenerListDetailSegue", sender: self)
        
        // Stop scanning for new peripherals
        toggleScanMode(startScanning: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ListenerListDetailSegue" {
            let destinationViewController: ListenerDetailViewController = segue.destinationViewController as! ListenerDetailViewController

            destinationViewController.peripheralData = selectedPeripheralData
            destinationViewController.peripheralStore = peripheralStore
            destinationViewController.simpleCentral = simpleCentral
        }
    }
}

// MARK: SimpleCentralDelegate methods
extension ListenerViewController {
    func discoveredPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Add discovered peripheral to our general data store
        let peripheralData = peripheralStore.addDiscoverPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)

        dataSource.addItem(peripheralData.identifier)
                
        // Update the tableview with newest peripheral
        reloadData()
    }
}

// MARK: Private methods
extension ListenerViewController {
    func peripheralAtIndexPath(indexPath: NSIndexPath) -> PeripheralData? {
        let identifier = dataSource.itemAtIndexPath(indexPath)        
        return peripheralStore.peripheralWithIdentifier(identifier)
    }
    
    func toggleScanMode(startScanning startScanning: Bool) {
        // --     
        if startScanning {
            scanButton.setTitle("Stop Scan", forState: UIControlState.Normal)
            
            let uuid = String.convertToCBUUID(serviceIDTextField.text)
            simpleCentral.startListening(uuid)
        } else {
            scanButton.setTitle("Start Scan", forState: UIControlState.Normal)
            simpleCentral.stopListening()
        }
        
        isScanning = !isScanning
    }
    
    func clearDataSource() {
        dataSource.clear()
        reloadData()
    }
    
    func reloadData() {
        dispatch_async(dispatch_get_main_queue()) {
            let delay = 1.0 // delay by 1 second
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue(), {
                // Update the tableview with newest peripheral
                self.tableView.reloadData()
                
            })
        }
    }
}