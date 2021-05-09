//
//  Contact+CoreDataClass.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/24.
//
//

import Foundation
import CoreData

@objc(Contact)
public class Contact: NSManagedObject {
    var checked: Bool = false
    var status: SharingStatus = .none
}

enum SharingStatus {
    case none
    case ready
    case sharing
}
