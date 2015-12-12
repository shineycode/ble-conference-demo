//
//  PeripheralData.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

struct BLEServiceUUID {
    static let DeviceInformation = "180A"
}

struct BLECharacteristicUUID {
    static let ManufacturerName = "2A29"
    static let ModelNumber = "2A24"
    static let SerialNumber = "2A25"
    static let HardwareRevision = "2A27"
    static let FirmwareRevision = "2A26"
    static let SoftwareRevision = "2A28"
}

class PeripheralData {
    var identifier: String
    var rawPeripheral: CBPeripheral

    var displayName: String {
        guard let name = rawPeripheral.name else {
            return "Unknown name"
        }

        return name
    }

    var advertisementData: [String: AnyObject]
    var RSSI: NSNumber = 0

    var services = [String: ServiceData]()

    init(peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        identifier = PeripheralData.generateIdentifier(peripheral)
        rawPeripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
    }

    // Because we want to obfuscate how we're generating the unique identifier
    static func generateIdentifier(peripheral: CBPeripheral) -> String {
        return peripheral.identifier.UUIDString
    }

    func addServiceData(service: ServiceData) {
        services[service.identifier] = service
    }

    func findServiceData(service: CBService) -> ServiceData? {
        let identifier = ServiceData.generateIdentifier(service)
        return findServiceDataById(identifier)
    }
    
    func findServiceDataById(identifier: String) -> ServiceData? {
        guard let existingService = services[identifier] else {
            return nil
        }
        
        return existingService
    }
}

class ServiceData {
    var identifier: String
    
    var name: String {
        if rawService.UUID.UUIDString == BLEServiceUUID.DeviceInformation {
            return rawService.UUID.description
        } else {
           return rawService.UUID.UUIDString
        }
    }
    
    var rawService: CBService
    private var characteristics = [String]()
    private var characteristicsLookup = [String: CharacteristicData]()
    
    init(rawService: CBService, characteristics: [CharacteristicData]?) {
        identifier = ServiceData.generateIdentifier(rawService)
        self.rawService = rawService
       
        if let allCharacteristics = characteristics {
            for characteristicData in allCharacteristics {
                addCharacteristicData(characteristicData)
            }
        }
    }

    // Because we want to obfuscate how we're generating the unique identifier
    static func generateIdentifier(service: CBService) -> String {
        return service.UUID.UUIDString
    }

    func addCharacteristicData(characteristicData: CharacteristicData) {
        characteristicsLookup[characteristicData.identifier] = characteristicData
        characteristics.append(characteristicData.identifier)
    }
    
    func findCharacteristicDataById(identifier: String) -> CharacteristicData? {
        guard let existingCharacteristic = characteristicsLookup[identifier] else {
            return nil
        }
        
        return existingCharacteristic
    }
}
extension String {
    mutating func addCharacteristicProperty(value: String) {
        if self.characters.count > 0 {
            self = self + ", "
        }
        
        self += value
    }
}

class CharacteristicData {
    var identifier: String
    
    var name: String {
        switch (rawCharacteristic.UUID.UUIDString) {
        case BLECharacteristicUUID.ManufacturerName,
             BLECharacteristicUUID.ModelNumber,
             BLECharacteristicUUID.SerialNumber,
             BLECharacteristicUUID.SoftwareRevision,
             BLECharacteristicUUID.HardwareRevision,
             BLECharacteristicUUID.FirmwareRevision:
            return rawCharacteristic.UUID.description
        default:
            return rawCharacteristic.UUID.UUIDString
        }
    }    
    var propertyAsString: String {
        var value: String = ""
        let readWriteProperty: CBCharacteristicProperties = [CBCharacteristicProperties.Read, CBCharacteristicProperties.Write]

        switch (rawCharacteristic.properties) {
        case CBCharacteristicProperties.Broadcast:
            value.addCharacteristicProperty("B")
        case CBCharacteristicProperties.Read:
            value.addCharacteristicProperty("R")
        case CBCharacteristicProperties.WriteWithoutResponse:
            value.addCharacteristicProperty("WWR")
        case CBCharacteristicProperties.Write:
            value.addCharacteristicProperty("W")
        case readWriteProperty:
            value.addCharacteristicProperty("R+W")
        case CBCharacteristicProperties.Notify:
            value.addCharacteristicProperty("N")
        case CBCharacteristicProperties.Indicate:
            value.addCharacteristicProperty("I")
        case CBCharacteristicProperties.AuthenticatedSignedWrites:
            value.addCharacteristicProperty("ASW")
        case CBCharacteristicProperties.ExtendedProperties:
            value.addCharacteristicProperty("EP")
        case CBCharacteristicProperties.NotifyEncryptionRequired:
            value.addCharacteristicProperty("NER")
        case CBCharacteristicProperties.IndicateEncryptionRequired:
            value.addCharacteristicProperty("IER")
        default:
            // Do nothing
            value += "-"
        }
        
        return value
    }
        
    var rawCharacteristic: CBCharacteristic
    
    var valueAsString: String {
        if let value = rawCharacteristic.value {
            if let stringValue = NSString(data: value, encoding: NSUTF8StringEncoding) as? String {
                return stringValue
            }
        }
        
        return "No value present"
    }
    
    init(rawCharacteristic: CBCharacteristic) {
        identifier = CharacteristicData.generateIdentifier(rawCharacteristic)
        self.rawCharacteristic = rawCharacteristic
    }

    static func generateIdentifier(characteristic: CBCharacteristic) -> String {
        return characteristic.UUID.UUIDString
    }    
}