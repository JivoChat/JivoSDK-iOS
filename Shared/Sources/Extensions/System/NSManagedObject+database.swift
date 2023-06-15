//
//  NSManagedObject+Extensions.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 07.02.2023.
//

import Foundation
import CoreData

fileprivate let JVDatabaseContextClientFinderKey = "jv_clientFinder"
typealias JVDatabaseContextClientFinder = (Int) -> JVClient?

extension NSManagedObjectContext {
    func jv_setClientFinder(finder: @escaping JVDatabaseContextClientFinder) {
        userInfo.setObject(finder, forKey: JVDatabaseContextClientFinderKey as NSString)
    }
}

extension NSManagedObject {
    func jv_retrieveClient(id: Int) -> JVClient? {
        guard let context = managedObjectContext
        else {
            return nil
        }
        
        guard let finder = context.userInfo.object(forKey: JVDatabaseContextClientFinderKey) as? JVDatabaseContextClientFinder
        else {
            return nil
        }
        
        return finder(id)
    }
}

extension Optional where Wrapped: NSManagedObject {
    func jv_ifValid() -> Wrapped? {
        return self
    }
}
