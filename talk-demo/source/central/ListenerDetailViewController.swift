//
//  ListenerDetailViewController.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class ListenerDetailViewController: ViewController, SimpleCentralDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var advertisingDataTextView: UITextView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var peripheralData: PeripheralData?
    var peripheralStore: PeripheralStore?
    
    var simpleCentral: SimpleCentral? {
        didSet {
            simpleCentral?.delegate = self
        }
    }
   
    lazy private var tableViewDataSource: ListenerDetailTableViewDataSource = {
        return ListenerDetailTableViewDataSource()
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: SimpleCentralDelegate
extension ListenerDetailViewController {
    func discoveredServices(services: [CBService], associatedPeripheral: CBPeripheral) {
        addServices(services, peripheral: associatedPeripheral)
        reloadData()
        
        toggleConnectButtonAndTableView(false)
    }

    private func addServices(services: [CBService], peripheral: CBPeripheral) {
        guard let store = peripheralStore else {
            return
        }

        // Add this to the peripheral store
        let peripheralServices = store.addDiscoveredServices(services, associatedPeripheral: peripheral)

        // Update the tableView datasource as well
        tableViewDataSource.addSections(peripheralServices)
    }

    func discoveredCharacteristics(characteristics: [CBCharacteristic], associatedService:CBService, associatedPeripheral: CBPeripheral) {
        addCharacteristics(characteristics, service: associatedService, peripheral: associatedPeripheral)
        reloadData()
    }
    
    private func addCharacteristics(characteristics: [CBCharacteristic], service:CBService, peripheral: CBPeripheral) {
        guard let store = peripheralStore else {
            return
        }

        // Add the new characteristics to the peripheral store
        guard let result = store.addDiscoveredCharacteristics(characteristics, associatedService: service, associatedPeripheral: peripheral) else {
            return
        }

        // Update the tableView datasource with the new charactericts
        tableViewDataSource.addRows(result.addedCharacteristics, forServiceData:result.serviceData)
    }
    
    func receivedValueForCharacteristic(characteristic: CBCharacteristic, value: NSData?, peripheral: CBPeripheral) {
        print("characteristic: \(characteristic), value: \(value)")
        updateCharacteristicValue(value, forCharacteristic:characteristic, peripheral: peripheral)
        reloadData()
    }
    
    private func updateCharacteristicValue(value: NSData?, forCharacteristic characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        guard let store = peripheralStore else {
            return
        }
        
        // Find the section associated
        guard let serviceData = store.serviceDataForPeripheral(peripheral, characteristic: characteristic) else {
            return
        }

        // Find existing characteristic and update it
        guard let characteristicData = store.updateCharacteristicValue(value, forCharacteristic:characteristic, associatedPeripheral: peripheral) else {
            return
        }
        
        tableViewDataSource.updateRowData(characteristicData, serviceData:serviceData)
    }
    
    func disconnectedFromPeripheral(peripheral: CBPeripheral) {
        var friendlyName = ""
        if let name = peripheral.name {
            friendlyName = name
        } else {
            friendlyName = peripheral.identifier.UUIDString
        }
       
        if self.tableView.alpha < 1.0 {
            let alertViewController = UIAlertController(title: "Peripheral disconnected",
                message: "Peripheral \(friendlyName) disconnected from Central. Try again",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alertViewController.addAction(UIAlertAction(title: "Ok",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    // Show connect button only if tableview wasn't already visible, showing services & characteristics data
                    self.toggleConnectButtonAndTableView(true)
            }))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
}

// MARK: View lifecycle
extension ListenerDetailViewController {
    override func viewDidLoad() {
        self.title = "Advertisement"
        
        guard let profile = peripheralData else {
            nameLabel.text = "ERROR: Peripheral without data"
            return
        }
        
        nameLabel.text = profile.displayName
        
        identifierLabel.text = profile.rawPeripheral.identifier.UUIDString
        RSSILabel.text = profile.RSSI.stringValue
        
        progressIndicator.hidden = true
        
        // Tableview configuration
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alpha = 0.0
        
        // General configuration
        let advertisementData = profile.advertisementData
        advertisingDataTextView.text = advertisementData.debugDescription
        
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber {
            connectButton.enabled = connectable.boolValue
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        guard let data = peripheralData else {
            return
        }
        
        guard let central = simpleCentral else {
            return
        }
        
        central.disconnect(data.rawPeripheral)
    }
}

// MARK: User actions
extension ListenerDetailViewController {
    @IBAction func onConnectPress(sender: AnyObject) {
        guard let data = peripheralData else {
            return
        }
        
        guard let central = simpleCentral else {
            return
        }
        
        print("Connecting to peripheral: \(data.rawPeripheral)")
        central.connect(data.rawPeripheral)
        
        connectButton.setTitle("Connecting...", forState: UIControlState.Normal)
        progressIndicator.hidden = false
    }
}

// MARK: UITableViewDataSource/UITableViewDelegate
extension ListenerDetailViewController {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewDataSource.countOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = tableViewDataSource.sectionDataAtSection(section) else {
            return 0
        }
        
        return sectionData.countOfRows
    }
  
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionData = tableViewDataSource.sectionDataAtSection(section) else {
            return nil
        }
        
        return sectionData.title
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListenerDetailTableViewCell", forIndexPath: indexPath) as! ListenerDetailTableViewCell
        
        if let result = tableViewDataSource.itemAtIndexPath(indexPath) {
            cell.rowData = result.rowData
        } else {
            cell.rowData = nil
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: Private methods
extension ListenerDetailViewController {
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
    
    func toggleConnectButtonAndTableView(showConnectButton: Bool) {
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.connectButton.hidden = !showConnectButton
            self.progressIndicator.hidden = showConnectButton
            self.tableView.alpha = 1.0
        })
    }
}