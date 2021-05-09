//
//  Dest.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/22.
//

import Foundation
import MapKit

class LSCManager {
    static let shared = LSCManager()
    private init() {}
    
    var isSharing = false
    
    var routeCount = 0
    
    var sharedContacts: [CommonContact]?
    
    var myGPSDetail: GPSDetail?
    
    var myEngineStatus = 1
    
    var destination = [LocInfo]() {
        didSet {
            if destination.isEmpty {
                routes = nil
            }
        }
    }
    
    var routes: [MKRoute]?
    
    var totalDistLeft: DistanceType?
    
    var totalTimeLeft: TimeInterval?
    
    var isRouteExist = false {
        didSet {
            if !isRouteExist {
                destination.removeAll()
                routes = nil
            }
        }
    }
    
    var lsStartRequestData: LsStartRequest {
        var data = LsStartRequest(destination: nil)
        data.destination = destination
        return data
    }
}

class CommonContact {
    var phoneNum: String!
    var status: SharingStatus!
}
