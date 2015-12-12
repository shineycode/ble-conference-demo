//
//  TableRow.swift
//  talk-demo
//
//  Created by Shiney Code on 10/25/15.
//  Copyright © 2015 Shiney Code. All rights reserved.
//

import Foundation
import CoreBluetooth

class TableRow {
    var identifier: String

    var title: String?
    var content: String?
    var accessoryText: String?

    init(characteristicsData: CharacteristicData, content: String) {
        identifier = TableRow.generateIdentifier(characteristicsData)
        self.title = characteristicsData.name
        self.content = content
        self.accessoryText = characteristicsData.propertyAsString
    }

    static func generateIdentifier() -> String {
        return NSUUID().UUIDString
    }

    static func generateIdentifier(characteristicsData: CharacteristicData) -> String {
        return characteristicsData.identifier
    }
}

class TableSection {
    private(set) var title: String
    private(set) var identifier: String

    private(set) var rows = [String]()
    private var rowLookup = [String: TableRow]()

    var countOfRows: Int {
        return rows.count
    }
    
    init(serviceData: ServiceData) {
        self.identifier = TableSection.generateIdentifier(serviceData)
        self.title = serviceData.name
    }

    init(title: String, identifier: String) {
        self.title = title
        self.identifier = identifier
    }

    static func generateIdentifier() -> String {
        return NSUUID().UUIDString
    }
    
    static func generateIdentifier(serviceData: ServiceData) -> String {
        return serviceData.identifier
    }

    func addTableRow(row: TableRow) {
        rows.append(row.identifier)
        rowLookup[row.identifier] = row
    }
    
    func rowDataAtRow(rowIndex: Int) -> TableRow? {
        let rowId = rows[rowIndex]
        return rowLookup[rowId]
    }

    func rowDataById(identifier: String) -> TableRow? {
        guard let rowIndex = rows.indexOf(identifier) else {
            return nil
        }
        return rowDataAtRow(rowIndex)
    }
}

class ListenerDetailTableViewDataSource {
    var countOfSections: Int {
        return sections.count
    }
    
    private var sections = [String]()
    private var sectionLookup = [String: TableSection]()

    func addSections(services: [ServiceData]) {
        for service in services {
            let tableSection = TableSection(serviceData: service)

            sectionLookup[tableSection.identifier] = tableSection

            sections.append(tableSection.identifier)
        }
    }
    
    func addRows(characteristicsData: [CharacteristicData], forServiceData serviceData: ServiceData) {
        // Find the section that this service belongs to
        let identifier = TableSection.generateIdentifier(serviceData)

        guard let section = sectionLookup[identifier] else {
            return
        }

        // Now add the characteristics as rows.
        for characteristicData in characteristicsData {
            let content = characteristicData.valueAsString
            let tableRow = TableRow(characteristicsData: characteristicData, content: content)
            section.addTableRow(tableRow)
        }
    }
    
    func updateRowData(characteristicData: CharacteristicData, serviceData: ServiceData) {
        // Figure out which section/row this characteristic lives in
        let sectionIdentifier = TableSection.generateIdentifier(serviceData)

        guard let section = sectionLookup[sectionIdentifier] else {
            return
        }

        // Find the row this characteristic lives in
        let rowIdentifier = TableRow.generateIdentifier(characteristicData)

        guard let tableRow = section.rowDataById(rowIdentifier) else {
            return
        }

        tableRow.title = characteristicData.name
        tableRow.content = characteristicData.valueAsString
    }
    
    func sectionDataAtSection(sectionIndex: Int) -> TableSection? {
        precondition(sectionIndex < sections.count && sections.count > 0, "Section exceeds size of data source contents")
        
        let sectionItemId = sections[sectionIndex]
        guard let sectionData = sectionLookup[sectionItemId] else {
            return nil
        }
        
        return sectionData
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> (sectionData: TableSection, rowData: TableRow)? {
        precondition(indexPath.section < sections.count && sections.count > 0, "Section exceeds size of data source contents")
//        precondition(indexPath.row < rows.count && rows.count > 0, "Row exceeds size of data source contents")
        
        if let sectionData = sectionDataAtSection(indexPath.section) {
            if let rowData = sectionData.rowDataAtRow(indexPath.row) {
                return (sectionData: sectionData, rowData: rowData)
            }
        }
        
        return nil
    }
    
    func clear() {
        sections.removeAll()
        sectionLookup.removeAll()
    }
}

