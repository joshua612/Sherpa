//
//  Model.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/22.
//

import Foundation
import CoreLocation

//MARK: 위치 공유 시작
struct LsStartRequest: Codable {
    var destination: [LocInfo]?
}

struct LocInfo: Codable {
    var addr: String
    var name: String
    var coord: Coord
    var waypointID: Int?    // 0 or null = dest , 1 ~ = first waypoint
    var distLeft: DistanceType? // not use on waypoint
    var timeLeft: TimeInterval? // not use on waypoint
    
    init(addr: String, name: String, coord: Coord) {
        self.addr = addr
        self.name = name
        self.coord = coord
    }
    
    init(addr: String, name: String, coord: CLLocationCoordinate2D) {
        self.addr = addr
        self.name = name
        self.coord = Coord(coord)
    }
    
    init(addr: String, name: String, coord: Coord, waypointID: Int?, distLeft: DistanceType?, timeLeft: TimeInterval?) {
        self.addr = addr
        self.name = name
        self.coord = coord
        self.waypointID = waypointID
        self.distLeft = distLeft
        self.timeLeft = timeLeft
    }
}

struct Coord: Codable {
    var lat: Double
    var lon: Double
    var alt: Double?
    var type: Int
    var heading: Double?
    var velocity: Double?
    
    init(_ coord: CLLocationCoordinate2D) {
        self.lat = coord.latitude
        self.lon = coord.longitude
        self.type = 0
    }
    
    init(lat: Double, lon: Double, alt: Double?, heading: Double?, velocity: Double?) {
        self.lat = lat
        self.lon = lon
        self.alt = alt
        self.type = 0
        self.heading = heading
        self.velocity = velocity
    }
    
    init(_ coord: CLLocationCoordinate2D, alt: Double?, heading: Double?, velocity: Double?) {
        self.lat = coord.latitude
        self.lon = coord.longitude
        self.alt = alt
        self.type = 0
        self.heading = heading
        self.velocity = velocity
    }
    
    func toCLCoord()-> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
    }
}

struct DistanceType: Codable {
    let value: Double?
    let unit: Int?  // 0 = feet, 1 = km, 2 = meter, 3 = miles
    
    init(value: Double, unit: Int) {
        self.value = value > 0 ? value : 0
        self.unit = unit
    }
}

struct TimeInterval: Codable {
    let value: Int
    let unit: Int   // 0 = hour. 1 = min, 2 = msec, 3 = sec
    
    init(value: Int, unit: Int) {
        self.value = value > 0 ? value : 0
        self.unit = unit
    }
    
    init(value: Double, unit: Int) {
        self.value = value > 0 ? Int(value) : 0
        self.unit = unit
    }
}


//MARK: 현재 차량 위치 공유
struct LsDataRequest: Codable {
    let currentLocation: [GPSDetail]
    let distLeft: DistanceType?
    let timeLeft: TimeInterval?     // min
}

struct GPSDetail: Codable {
    let coord: Coord
    let head: Int?
    let speed: Velocity
    let accuracy: Accuracy?
    let time: String
}

struct Velocity: Codable {
    let value: Int
    let unit: Int
}

struct Accuracy: Codable {
    let hdop: Int
    let pdop: Int
}

//MARK: 목적지 설정
struct SetDestRequest: Codable {
    let vehicleLoc: GPSDetail
    let destination: [LocInfo]?
    let ignStatus: Int  // 0 = off, 1 = on
    let destStatus: Int?    // 0 = dest cancel, 1 = dest setting, 2 = dest arrival
    let wayPointInfo: [LocInfo]?
}

//MARK: 위치 공유 수신자 목록 업데이트
struct LsListRequest: Codable {
    let locSharingList: [LocSharing]?
}

struct LocSharing: Codable {
    let phoneNum: String
    let profileName: String?
    let sharerType: Int?    // 0 = web, 1 = app, 2 = car
    let remainTime: TimeInterval?   // sec
    let lsStatus: Int   // 0 = none share, 1 = share, 2 = renewal
    let message: String?
}

//MARK: 위치 공유 시간 연장
struct LocationSharingExtendRequest: Codable {
    let phoneNum: [String]
    let timeLeft: TimeInterval?
}
