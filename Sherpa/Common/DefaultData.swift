//
//  CommonData.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/19.
//

import Foundation
import CoreLocation


let DEFAULT_START_POINT: CLLocationCoordinate2D = CLLocationCoordinate2DMake(35.68097475674554, 139.7671462576847)
let DEFAULT_DESTINATION: CLLocationCoordinate2D = CLLocationCoordinate2DMake(35.70562012878824, 139.75174082587162)

let MY_PIN_TITLE: String = "MyCar"

let DEFAULT_ZOOM_LEVEL = 3

//let BASE_URL = "http://repo.poliot.co.kr:8072/"   // Mock 서버
let BASE_URL = "http://192.168.1.32:8080/"         // 박운형 선임님 서버

let EXTEND_TIME: TimeInterval = TimeInterval(value: 15, unit: 1)

var LOCATION_SHARING_START_URL: String {
    BASE_URL + "LSC/2/start"
}

var CURRENT_LOCATION_SHARING_URL: String {
    BASE_URL + "LSC/2/locdata/car"
}

var SET_DESTINATION_URL: String {
    BASE_URL + "gis/setDestination"
}

var LOCATION_SHARING_CANCEL_URL: String {
    BASE_URL + "LSC/2/cancel"
}

var LOCATION_SHARING_RECIPIENT_LIST_UPDATE_URL: String {
    BASE_URL + "LSC/2/list"
}

var LOCATION_SHARING_TIME_EXTEND_URL: String {
    BASE_URL + "LSC/2/extend"
}


