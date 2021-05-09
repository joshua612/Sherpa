//
//  MapCalculator.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/19.
//

import Foundation
import MapKit

class MapCalculator {
    // 시속 계산 함수
    func calcSpeed(secTime: Double, distance: CLLocationDistance)-> Double {
        return distance / (secTime/60) * 60 / 1000
    }
    
    // 방향 계산 함수
    func calcHeading(laGap: Double, loGap: Double)-> Double {
        let value = atan2(laGap, loGap) * 180/Double.pi
        let degree: Double = 360 - 90 - value
        return degree >= 360 ? degree - 360 : degree
    }
    
    // 시간 정리 함수
    func getCurrentTime()-> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        return formatter.string(from: date)
    }
    
    // 초당 좌표 진행, 방향 계산
    func calCoordPerSecAndHeading(last: CLLocationCoordinate2D, next: MKRoute.Step, distancePerSec: Double)-> Section {
        let distance = next.distance
        let laGap = last.latitude - next.polyline.coordinate.latitude
        let loGap = last.longitude - next.polyline.coordinate.longitude
        
        let distancePerSecRate = distancePerSec / distance
        
        return Section(distance: distance, laCoordPerSec: laGap * distancePerSecRate, loCoordPerSec: loGap * distancePerSecRate, heading: calcHeading(laGap: laGap, loGap: loGap))
    }
    
    // 도분초로 좌표 사이 거리 계산
    func getDistanceFromCoord(sectionStartCoord: CLLocationCoordinate2D, sectionEndCoord: CLLocationCoordinate2D)-> Double {
        // (sectionStartCoord, sectionEndCoord)
        let startLat: Double = sectionStartCoord.latitude
        let startLon: Double = sectionStartCoord.longitude
        
        let destLat: Double = sectionEndCoord.latitude
        let destLon: Double = sectionEndCoord.longitude
        
        let startLatDeg: Int = Int(startLat)
        let startLatMin: Int = Int((startLat - Double(startLatDeg)) * 60)
        let startLatSec: Double = ((startLat - Double(startLatDeg)) * 60 - Double(startLatMin)) * 60
        
        let startLonDeg: Int = Int(startLon)
        let startLonMin: Int = Int((startLon - Double(startLonDeg)) * 60)
        let startLonSec: Double = ((startLon - Double(startLonDeg)) * 60 - Double(startLonMin)) * 60
        
        let destLatDeg: Int = Int(destLat)
        let destLatMin: Int = Int((destLat - Double(destLatDeg)) * 60)
        let destLatSec: Double = ((destLat - Double(destLatDeg)) * 60 - Double(destLatMin)) * 60
        
        let destLonDeg: Int = Int(destLon)
        let destLonMin: Int = Int((destLon - Double(destLonDeg)) * 60)
        let destLonSec: Double = ((destLon - Double(destLonDeg)) * 60 - Double(destLonMin)) * 60
        
        let latGapDeg: Int = startLatDeg - destLatDeg
        let latGapMin: Int = startLatMin - destLatMin
        let latGapSec: Double = startLatSec - destLatSec
        
        let lonGapDeg: Int = startLonDeg - destLonDeg
        let lonGapMin: Int = startLonMin - destLonMin
        let lonGapSec: Double = startLonSec - destLonSec
        
        let lonDegA: Double = Double(lonGapDeg) * 88.9
        let lonMinA: Double = Double(lonGapMin) * 1.48
        let lonSecA: Double = lonGapSec * 0.025
        
        let latDegA: Double = Double(latGapDeg) * 111.3
        let latMinA: Double = Double(latGapMin) * 1.86
        let latSecA: Double = latGapSec * 0.031
        
        let lonGapDms: Double = pow(lonDegA + lonMinA + lonSecA, 2)
        let latGapDms: Double = pow(latDegA + latMinA + latSecA, 2)
        
        let distance = (sqrt(lonGapDms + latGapDms)) * 1000
        
        return distance
    }
    
}
