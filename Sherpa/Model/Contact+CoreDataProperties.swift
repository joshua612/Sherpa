//
//  Contact+CoreDataProperties.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/24.
//
//

import Foundation
import CoreData


extension Contact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }

    @NSManaged public var name: String?
    @NSManaged public var num: String?

}

extension Contact : Identifiable {
    func setData(name: String, num: String) {
        self.name = name
        self.num = num
    }
}
