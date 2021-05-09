//
//  UUData+CoreDataProperties.swift
//  Sherpa
//
//  Created by 고준권 on 2021/03/25.
//
//

import Foundation
import CoreData


extension UUData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UUData> {
        return NSFetchRequest<UUData>(entityName: "UUData")
    }

    @NSManaged public var nadID: String?
    @NSManaged public var vin: String?

}

extension UUData : Identifiable {

}
