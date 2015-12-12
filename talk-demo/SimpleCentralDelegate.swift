//
//  SimpleCentralDelegate.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol SimpleCentralDelegate {
    func discoveredPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    func discoveredServices(services: [CBService], associatedPeripheral: CBPeripheral)
    func discoveredCharacteristics(characteristics: [CBCharacteristic], associatedService:CBService, associatedPeripheral: CBPeripheral)
    func receivedValueForCharacteristic(characteristic: CBCharacteristic, value: NSData?, peripheral: CBPeripheral)
    
    func disconnectedFromPeripheral(peripheral: CBPeripheral)
}

extension SimpleCentralDelegate {
    func discoveredPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {}
    func discoveredServices(services: [CBService], associatedPeripheral: CBPeripheral) {}
    func discoveredCharacteristics(characteristics: [CBCharacteristic], associatedService:CBService, associatedPeripheral: CBPeripheral) {}
    func receivedValueForCharacteristic(characteristic: CBCharacteristic, value: NSData?, peripheral: CBPeripheral) {}
    func disconnectedFromPeripheral(peripheral: CBPeripheral) {}
}