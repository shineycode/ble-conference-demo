//
//  Central.swift
//  talk-demo
//
//  Created by Benjamin Deming on 10/25/15.
//  Copyright © 2015 Benjamin Deming. All rights reserved.
//

import CoreBluetooth

/**
 This central will connect to any peripherals advertising the service
 `Peripheral.serviceUUID` and acknowledge them by updating the write characteristic on the service.
 
 It derives from NSObject so it may conform to CBCentralManagerDelegate
 */
class Central: NSObject {
    //
    //
    // State management that is exposed to the view controller.
    //
    //
    enum State {
        case Idle
        case Scanning
        case HeardPing
    }
    
    var currentState: State = .Idle {
        didSet {
            currentStateChangedHandler?(currentState)
        }
    }
    
    var currentStateChangedHandler: ((Central.State) -> (Void))?
    
    //
    //
    // Central manager & discovered peripheral
    //
    //
    private var centralManagerDelegateQueue = dispatch_queue_create(
        "cocoaconf.talk-demo.DelegateQ",
        DISPATCH_QUEUE_SERIAL
    )
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var peripheralWriteCharacteristic: CBCharacteristic!
    
    //
    //
    // Lifecycle
    //
    //
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: centralManagerDelegateQueue)
    }
    
    deinit {
        if let peripheral = discoveredPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

//
//
// MARK: Central related operations
//
//
extension Central: CBCentralManagerDelegate {
    //
    //
    // MARK: CBCentralManagerDelegate
    //
    //
    @objc func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            currentState = .Scanning
            startScanning()
        default:
            print("Cannot start scanning for pinging peripherals")
            currentState = .Idle
        }
    }
    
    //
    //
    // Starting and stopping scanning
    //
    //
    func startScanning() {
        centralManager.scanForPeripheralsWithServices([Peripheral.serviceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    //
    //
    // Discovery & connection of peripheral
    //
    //
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered peripheral advertising: \n \(advertisementData)")
        discoveredPeripheral = peripheral
        
        stopScanning()
        
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected to peripheral.")
        peripheral.delegate = self
        peripheral.discoverServices([Peripheral.serviceUUID])
    }
}

//
//
// MARK: CBPeripheralDelegate
//
//
extension Central: CBPeripheralDelegate {
    //
    //
    // 
    // Service and characteristic discovery on connected peripheral
    //
    //
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard let service = peripheral.services?.filter({ $0.UUID == Peripheral.serviceUUID }).first else {
            return
        }
        
        print("Discovered the peripheral's service")
        
        let characteristicIDs = [Peripheral.notifyCharacteristicUUID, Peripheral.writeCharacteristicUUID]
        peripheral.discoverCharacteristics(characteristicIDs, forService: service)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let notifyCharacteristic = service.characteristics?.filter({ $0.UUID == Peripheral.notifyCharacteristicUUID }).first else {
            return
        }
        
        guard let writeCharacteristic = service.characteristics?.filter({ $0.UUID == Peripheral.writeCharacteristicUUID}).first else {
            return
        }
        
        self.peripheralWriteCharacteristic = writeCharacteristic
        
        print("Discovered the peripheral's service's characteristics")
        peripheral.setNotifyValue(true, forCharacteristic: notifyCharacteristic)
    }
    
    //
    //
    // Receiving updates for the peripheral's characteristics
    // This is how we receive the ping message from a peripheral –– Message.PING as its data 
    // representation in the notify characteristic's value
    //
    //
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Value of the characteristic was updated")
        
        guard let pingData = characteristic.value else {
            return
        }
        
        guard let message = Message(rawValue: pingData) where message == Message.PING else {
            print("Could not build message from characteristic.")
            return
        }
        
        print("Received ping")
        
        currentState = .HeardPing
        
        print("Acknowledging ping.")
        
        let ack = Message.ACK
        peripheral.writeValue(ack.rawValue, forCharacteristic: peripheralWriteCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    //
    //
    // Updating values of characteristics on our discovered peripheral's services
    // This is how we send the ack message to the peripheral –– update the peripheral's write
    // characteristic value with the data representation of Message.ACK
    //
    //
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Wrote to characteristic. Error: \(error)")
        centralManager.cancelPeripheralConnection(peripheral)
    }
}