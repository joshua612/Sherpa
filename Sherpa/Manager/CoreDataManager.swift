//
//  CoreDataManager.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/24.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared: CoreDataManager = CoreDataManager()
    private init() {}
    
    let context = AppDelegate().persistentContainer.viewContext
    
    let contactEntityName = "Contact"
    let bookmarkEntityName = "Bookmark"
    let uuDataEntityName = "UUData"
    
    func getContacts()-> [Contact] {
        var contacts = [Contact]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: contactEntityName)
        
        do {
            if let result = try context.fetch(fetchRequest) as? [Contact] {
                contacts = result.sorted(by: {
                    $0.name!.lowercased() < $1.name!.lowercased()
                })
            }
        } catch {
            print("get Contacts Error")
        }
        
        return contacts
    }
    
    func saveContact(name: String, num: String)-> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: contactEntityName, in: context) else {return false}
        
        guard let contact = NSManagedObject(entity: entity, insertInto: context) as? Contact else {return false}
        contact.setData(name: name, num: num)
        
        do {
            try context.save()
            return true
        } catch {
            print("save Contact Error")
            return false
        }
    }
    
    func deleteContact(_ contact: Contact)-> Bool {
        context.delete(contact)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    func getBookmarks()-> [Bookmark] {
        var bookmarks = [Bookmark]()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: bookmarkEntityName)
        
        do {
            if let result = try context.fetch(fetchRequest) as? [Bookmark] {
                bookmarks = result.sorted(by: {
                    $0.name!.lowercased() < $1.name!.lowercased()
                })
            }
        } catch {
            print("get Bookmarks Error")
        }
        
        return bookmarks
    }
    
    func saveBookmarks(name: String, address: String, latitude: Double, longitude: Double)-> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: bookmarkEntityName, in: context) else {return false}
        
        guard let bookmark = NSManagedObject(entity: entity, insertInto: context) as? Bookmark else {return false}
        bookmark.setData(name: name, address: address, latitude: latitude, longitude: longitude)
        
        do {
            try context.save()
            return true
        } catch {
            print("save Bookmarks Error")
            return false
        }
    }
    
    func deleteBookmark(_ bookmark: Bookmark)-> Bool {
        context.delete(bookmark)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    func getUUData() -> UUData? {
        var uuData: UUData?
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: uuDataEntityName)
        do {
            if let result = try context.fetch(fetchRequest) as? [UUData], let uuDataResult = result.first {
                uuData = uuDataResult
            }
        }catch {
            print("get UUData fail")
        }
        return uuData
    }
    
    func saveUUData(nadID: String, vin: String)-> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: uuDataEntityName, in: context) else {return false}
        guard let uuData = NSManagedObject(entity: entity, insertInto: context) as? UUData else {return false}
        uuData.nadID = nadID
        uuData.vin = vin
        
        do {
            try context.save()
            return true
        } catch {
            print("save UUData Error")
            return false
        }
    }
    
    func deleteUUData(_ uuData: UUData)-> Bool {
        context.delete(uuData)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    func save()-> Bool {
        do {
            try context.save()
            return true
        } catch {
            print("save UUData Error")
            return false
        }
    }
}
