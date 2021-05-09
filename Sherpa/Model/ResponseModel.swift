//
//  ResponseModel.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/22.
//

import Foundation

// 위치 공유 시작
struct LsStartResponse: Codable {
    let locShareConf: LocShareConf
}

struct LocShareConf: Codable {
    let sendInterval1: Int
    let gatherInterval1: Int?
    let sendInterval2: Int
    let gatherInterval2: Int?
    let duration: Int
    let remainTime: Int
}

// 현재 위치 공유
struct LsDataResponse: Codable {
    let locShareAckList: [LocShareAck]?
}

struct LocShareAck: Codable {
    let phoneNum: String
    let sharerType: Int
    let ackStatus: Int
}

// 위치 공유 수신자 목록 업데이트
struct LsListResponse: Codable {
    let locSharingList: [LocSharing]?
}


