//
//  PeripheralStore.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

class PeripheralStore {
    private(set) var peripherals: [String: PeripheralData]
    
    init() {
        peripherals = [String: PeripheralData]()
    }
    
    func peripheralWithIdentifier(identifier: String) -> PeripheralData? {
        guard let foundPeripheral = peripherals[identifier] else {
            return nil
        }
        
        return foundPeripheral
    }

    func serviceDataForPeripheral(peripheral: CBPeripheral, characteristic: CBCharacteristic) -> ServiceData? {
        let peripheralId = PeripheralData.generateIdentifier(peripheral)
        guard let peripheralData = peripheralWithIdentifier(peripheralId) else {
            return nil
        }

        return peripheralData.findServiceData(characteristic.service)
    }

    /**
     Adds the discovered peripheral to the local collection of peripherals
     */
    func addDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> PeripheralData {
        let peripheralData = PeripheralData(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
        peripherals[peripheralData.identifier] = peripheralData

        return peripheralData
    }

    /**
     Adds the discovered services to the already stored peripheral
     */
    func addDiscoveredServices(services: [CBService], associatedPeripheral: CBPeripheral) -> [ServiceData] {
        var addedServices = [ServiceData]()

        // Get the peripheral that's already stored. If it doesn't exist, we won't create one because we don't have
        // any advertisement data & RSSI associated with this unknown peripheral.
        let peripheralId = PeripheralData.generateIdentifier(associatedPeripheral)
        guard let peripheralData = peripherals[peripheralId] else {
            return addedServices
        }

        // Add these services to the existing collection for associated peripheral
        for service in services {
            let newService = ServiceData(rawService: service, characteristics: nil)
            peripheralData.addServiceData(newService)

            // Also add to local copy so we can return all added services back to the caller
            addedServices.append(newService)
        }

        return addedServices
    }

    func addDiscoveredCharacteristics(characteristics: [CBCharacteristic],
                                      associatedService:CBService,
                                      associatedPeripheral: CBPeripheral) -> (serviceData: ServiceData, addedCharacteristics: [CharacteristicData])? {
        var addedCharacteristics = [CharacteristicData]()

        let peripheralId = PeripheralData.generateIdentifier(associatedPeripheral)

        guard let peripheralData = peripherals[peripheralId] else {
            return nil
        }

        guard let serviceData = peripheralData.findServiceData(associatedService) else {
            return nil
        }

        // Add these characteristics to our existing collection for the associated service
        for characteristic in characteristics {
            print("Looking at characteristic: \(characteristic)")
            let characteristicData = CharacteristicData(rawCharacteristic: characteristic)
            serviceData.addCharacteristicData(characteristicData)

            // Also add to the local copy so we can return all added characteristics back to the caller
            addedCharacteristics.append(characteristicData)
        }

        return (serviceData: serviceData, addedCharacteristics: addedCharacteristics)
    }
    
    func updateCharacteristicValue(value: NSData?, forCharacteristic characteristic: CBCharacteristic, associatedPeripheral: CBPeripheral) -> CharacteristicData? {

        guard let _ = value else {
            return nil
        }
        
        let peripheralId = PeripheralData.generateIdentifier(associatedPeripheral)
        guard let peripheralData = peripherals[peripheralId] else {
            return nil
        }
        
        let serviceId = ServiceData.generateIdentifier(characteristic.service)
        guard let serviceData = peripheralData.findServiceDataById(serviceId) else {
            return nil
        }
        
        // Find the associated characteristic and update the value
        let charId = CharacteristicData.generateIdentifier(characteristic)
        guard let characteristicData = serviceData.findCharacteristicDataById(charId)else {
            return nil
        }
        
        return characteristicData
    }

    func clear() {
        peripherals.removeAll()
    }
}