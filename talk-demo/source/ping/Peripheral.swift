//
//  Peripheral.swift
//  talk-demo
//
//  Created by Benjamin Deming on 10/25/15.
//  Copyright © 2015 Benjamin Deming. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 Pings the current time in a notify characteristic value when centrals subscribe to the notify
 characteristic, then enters the acknowledged state via a write to its write characteristic.
 */
class Peripheral: NSObject {
    //
    //
    // State that is exposed to the view controller.
    //
    //
    enum State {
        case Idle
        case Advertising
        case Acknowledged(NSTimeInterval)
    }
    
    var currentState: State = .Idle {
        didSet {
            currentStateChangedHandler?(currentState)
        }
    }
    
    var currentStateChangedHandler: ((Peripheral.State) -> (Void))?
    
    //
    //
    // Peripheral manager
    //
    //
    private var peripheralManagerDelegateQueue = dispatch_queue_create(
        "cocoaconf.talk-demo.PeripheralQ",
        DISPATCH_QUEUE_SERIAL
    )
    private var peripheralManager: CBPeripheralManager!
    
    //
    //
    // Service and characteristic UUIDs
    //
    //
    static var serviceUUID: CBUUID {
        get {
            return CBUUID(string: "1011")
        }
    }
    
    static var notifyCharacteristicUUID: CBUUID {
        get {
            return CBUUID(string: "3ed26148-9747-4566-8010-8ad607a2d3f7")
        }
    }
    
    static var writeCharacteristicUUID: CBUUID {
        get {
            return CBUUID(string: "4C9363E8-B38A-4199-9F03-E04E1E50993F")
        }
    }
    
    //
    //
    // Advertising data, service, and our characteristics
    //
    //
    private var advertisingData: [String: AnyObject] = [
        CBAdvertisementDataLocalNameKey: UIDevice.currentDevice().name,
        CBAdvertisementDataServiceUUIDsKey: [Peripheral.serviceUUID]
    ]
    
    private var service: CBMutableService = CBMutableService(
        type: Peripheral.serviceUUID,
        primary: true
    )
    
    private var notifyCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(
        type: Peripheral.notifyCharacteristicUUID,
        properties: [CBCharacteristicProperties.Notify],
        value: nil,
        permissions: [CBAttributePermissions.Readable]
    )
    
    private var writeCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(
        type: Peripheral.writeCharacteristicUUID,
        properties: [CBCharacteristicProperties.WriteWithoutResponse],
        value: nil,
        permissions: [CBAttributePermissions.Writeable]
    )
    
    private var lastPingCharacteristicUpdateTime: NSTimeInterval = 0.0
    
    //
    //
    // Lifecycle
    //
    //
    override init() {
        service.characteristics = [notifyCharacteristic, writeCharacteristic]
        
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: peripheralManagerDelegateQueue)
    }
}

//
//
// MARK: CBPeripheralManagerDelegate & advertising operations
//
//
extension Peripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            print("About to begin advertising.")
            currentState = .Advertising
            startAdvertising()
        default:
            print("Not ready to act as a peripheral.")
            currentState = .Idle
        }
    }
    
    //
    //
    // Advertising operations
    //
    //
    func startAdvertising() {
        peripheralManager.startAdvertising(advertisingData)
        peripheralManager.addService(self.service)
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }
    
    //
    //
    // Handling centrals subscribing to us.
    // This is how we send the ping message to a central – when a central subscribes to our notify 
    // characteristic, we update the characteristic with the data representation of Message.PING
    //
    //
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        stopAdvertising()
        
        print("Central subscribed. Going to ping.")
        lastPingCharacteristicUpdateTime = NSDate().timeIntervalSince1970
        peripheralManager.updateValue(Message.PING.rawValue, forCharacteristic: notifyCharacteristic, onSubscribedCentrals: nil)
    }
    
    //
    //
    // Handling requests from a central to update our write characteristic
    // This is how we receive the ack message from a peripheral – our write characteristic is 
    // updated with the data representation of Message.ACK
    //
    //
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        guard let request = requests.filter({ $0.characteristic.UUID == Peripheral.writeCharacteristicUUID }).first else {
            return
        }
        
        guard let data = request.value where data.length > 0 else {
            return
        }
        
        let subdata = data.subdataWithRange(NSMakeRange(request.offset, data.length - request.offset))
        guard subdata.length > 0 else {
            return
        }
        
        guard let msg = Message(rawValue: subdata) where msg == Message.ACK else {
            print("Could not deserialize acknowledgement")
            return
        }
        
        let rtt = NSDate().timeIntervalSince1970 - lastPingCharacteristicUpdateTime
        currentState = .Acknowledged(rtt)
        
        peripheralManager.updateValue(subdata, forCharacteristic: writeCharacteristic, onSubscribedCentrals: nil)
    }
}