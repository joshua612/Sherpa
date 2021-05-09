//
//  DataModel.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/22.
//

import Foundation
import MapKit

// 구간별 거리, 좌표 간격, 방향 정의 데이터
struct Section {
    let distance: Double
    let laCoordPerSec: Double
    let loCoordPerSec: Double
    let heading: Double
}

class Pin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var address: String?
    
    init(coordinate: CLLocationCoordinate2D, placeName title: String?, address: String?) {
        self.coordinate = coordinate
        self.title = title
        self.address = address
    }
}
