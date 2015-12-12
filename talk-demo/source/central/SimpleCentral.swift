//
//  SimpleCentral.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import CoreBluetooth

/**
 This central will scan for nearby peripherals and connect to selected peripheral to retrieve services and characteristics published by the peripheral.

 It derives from NSObject so it may conform to CBCentralManagerDelegate
 */

class SimpleCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    //
    //
    // Central manager
    //
    //
    var centralManager: CBCentralManager!
    var delegate: SimpleCentralDelegate
    
    // Creating a serial queue to process work in FIFO manner
    private let centralManagerDelegateQueue = dispatch_queue_create("cocoaconf.talk-demo.CentralQ", DISPATCH_QUEUE_SERIAL)
    
    //
    //
    // State that is exposed to clients of this class
    //
    //
    enum SimpleCentralStartResult {
        case UnknownListenStartResult
        case StartedListening
        case AlreadyListening
        case NotReadyToListen
    }

    //
    //
    // Internal statement management
    //
    //
    enum CentralState {
        case NotReadyToListen
        case UpdateIminent
        case EnableAccess
        case ReadyForUse
        case BLEUnsupported
        case ScanningAdvertisements
        case ReadyToScan
    }
    
    private var centralState: CentralState = .NotReadyToListen

    internal(set) var services: Array<CBUUID>?    

    //
    //
    // Lifecycle
    //
    //
    init(delegate: SimpleCentralDelegate) {
        self.delegate = delegate
        
        super.init()
        
        let options:[String: AnyObject] = [
            CBCentralManagerOptionShowPowerAlertKey : false, // Suppress permission alert on initialization
        ]
        
        centralManager = CBCentralManager(delegate: self, queue: centralManagerDelegateQueue, options:options)
    }
    
    deinit {
        stopListening()
        centralManager.delegate = nil
    }
}

//
//
// MARK: CBCentralManagerDelegate
//
//
extension SimpleCentral  {
    //
    //
    // State change
    //
    //
    
    // State change is possible anytime the App is in use
    internal func centralManagerDidUpdateState(central: CBCentralManager) {
        
        switch (central.state) {
            // When state is unknown or resetting, an update is imminent. Therefore, we don't worry about things
        case CBCentralManagerState.Unknown, CBCentralManagerState.Resetting:
            centralState = .UpdateIminent
            
        case CBCentralManagerState.PoweredOff, CBCentralManagerState.Unauthorized:
            // Whenever we no longer have access, we need to stop listening for advertisements
            stopListening()
            centralState = .NotReadyToListen
            
        case CBCentralManagerState.PoweredOn:
            // As soon as we're ready, we can start listening for advertisements
            centralState = .ReadyForUse
            print("Ready to start scanning for nearby peripherals")
            
        case CBCentralManagerState.Unsupported:
            centralState = .BLEUnsupported
        }
    }
}

//
//
// MARK: Public methods
//
//
extension SimpleCentral {
    //
    //
    // Starting and stopping scanning
    //
    //
    func startListening(serviceUUID: CBUUID?) -> SimpleCentralStartResult {
        print("Attempting to start scan, current state: \(centralState)")

        // Convert UUID to array form and store all of the services we're scanning
        services = CBUUID.createArrayFromUUID(serviceUUID)
        
        if centralState == .ScanningAdvertisements {
            return SimpleCentralStartResult.AlreadyListening
        }

        // Disallow scanning for advertisements if Central is not ready yet
        if centralState != .ReadyForUse && centralState != .ReadyToScan {
            return SimpleCentralStartResult.NotReadyToListen
        }
        
        // Update state so we don't start another scan
        centralState = .ScanningAdvertisements
        
        // We want to scan for peripherals broadcasting with this list of UUIDs
        centralManager.scanForPeripheralsWithServices(services, options: nil)
        
        return SimpleCentralStartResult.StartedListening
    }
    
    func stopListening() {
        print("Attempting to stop scan, current state: \(centralState)")

        // No need to stop scanning if we aren't already doing it
        if centralState == .ReadyToScan {
            return
        }

        // Update state to indicate that we're ready to scan again
        centralState = .ReadyToScan
        
        centralManager.stopScan()
    }
    
    //
    //
    // Connection and disconnection of peripheral
    //
    //
    func connect(peripheral: CBPeripheral) {
        let options: [String : AnyObject] = [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]
        centralManager.connectPeripheral(peripheral, options: options)
    }
    
    func disconnect(peripheral: CBPeripheral) {
        peripheral.delegate = nil // stop being a delegate at this point
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

//
//
// MARK: CBCentralManagerDelegate
//
//
extension SimpleCentral  {
    //
    //
    // Peripheral discovery
    //
    //
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered peripheral \(peripheral.name), rssi: \(RSSI), advertisementData: \(advertisementData)")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.discoveredPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)
        }
    }
    
    //
    //
    // Peripheral connection and disconnect
    //
    //
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected to peripheral \(peripheral.name)")
        
        // We need to become a delegate in order to get notifications
        peripheral.delegate = self
        
        //
        //
        // Let's discover the services on connected peripheral
        //
        //
        
        // NOTE: If we provide a nil list, all services will be discovered, which is much slower and
        // not recommended per Apple Documentation.
        peripheral.discoverServices(services)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected from peripheral \(peripheral.name), error: \(error)")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.disconnectedFromPeripheral(peripheral)
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect to peripheral \(peripheral.name), error: \(error)")
    }
    
    //
    //
    // Service discovery on connected peripheral
    //
    //
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discover services for peripheral: \(peripheral.name ?? "Unnamed peripheral"), error: \(error)")
        
        if let services = peripheral.services {
            // Inform our delegate about this service
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.discoveredServices(services, associatedPeripheral: peripheral)
            }
            
            for service in services {
                print("Discovered service, uuid: \(service.UUID), service: \(service.isPrimary)")
                
                // Discover the characteristics associated with this service
                
                // NOTE: Typically, you'll want to specify the list of characteristics you're interested in.
                // Specifying nil means that all characteristics associated with this service will
                // be discovered and doing so may waste battery life.
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    //
    //
    // Characteristics discovery on connected peripheral
    //
    //
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Discovered characteristicsForService: \(service.UUID.UUIDString)")
        if let characteristics = service.characteristics {
            // Notify caller that we've discovered all of the requested characteristics for this service
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.discoveredCharacteristics(characteristics, associatedService:service, associatedPeripheral: peripheral)
            }
            
            // Now we want to read the value of the characteristic
            // NOTE: We're doing a single instance read here instead of notify
            for characteristic in characteristics {
                let properties: CBCharacteristicProperties = characteristic.properties
                let readWriteProperty: CBCharacteristicProperties = [CBCharacteristicProperties.Read, CBCharacteristicProperties.Write]
                
                // Read, Read+Write
                if properties == readWriteProperty || properties == CBCharacteristicProperties.Read {
                    peripheral.readValueForCharacteristic(characteristic)
                }
            }
        }
    }
    
    //
    //
    // Update of value available on the characteristic
    //
    //
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Updated characteristic: \(characteristic) with value: \(characteristic.value)")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.receivedValueForCharacteristic(characteristic, value:characteristic.value, peripheral: peripheral)
        }
    }
}