//
//  NetworkManager.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/25.
//

import Foundation
import Alamofire


typealias SuccessResult<T> = (T)-> Void
typealias ErrorResult = (String)-> Void

struct Log {
    var code: Int
    var name: String
    var time: String
    var msg: String
}

class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    private init() {}
    var msg: String = ""
    
    var logs: [Log] = [] {
        didSet {
            handler()
        }
    }
    
    var uuData: UUData!
    
//    let header: HTTPHeaders = [
//        "Content-Type" : "application/json",
//        "NADID" : uuData.nadID!,
//        "VIN" : uuData.vin!,
//        "TID" : "IrVkK77rR6aw0ZqdtVTOxg"
//    ]
    
    var header: HTTPHeaders {
        return [
            "Content-Type" : "application/json",
            "NADID" : uuData.nadID!,
            "VIN" : uuData.vin!,
            "TID" : "IrVkK77rR6aw0ZqdtVTOxg"
        ]
    }
    
    let networkErrorMsg = "Network Error"
    let jsonParsingErrorMsg = "Json Parsing Error"
    
    var handler: (() -> Void)!
    
    func jsonSerialize(_ obj: Any) throws -> Data {
        return try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
    }
    
    func logAppend(name: String, code: Int, msg: String) {
        logs.append(Log(code: code, name: name, time: "HH:mm:ss".stringFromDate(), msg: msg))
    }
    
    // 위치 공유 시작
    func postLocationSharingStart(_ requestBody: LsStartRequest, success: @escaping SuccessResult<LsStartResponse>, fail: @escaping ErrorResult) {
        do {
            var request = try URLRequest(url: LOCATION_SHARING_START_URL, method: .post, headers: header)
            request.httpBody = try JSONEncoder().encode(requestBody)
            AF.request(request).responseJSON { response in
//                // [hoxvi] 서버 응답코드
                guard let startShareStatusCode = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-A", code: startShareStatusCode, msg: "위치 공유 시작")
                switch response.result {
                case .success(let successResult) :
                    do {
                        let result = try JSONDecoder().decode(LsStartResponse.self, from: self.jsonSerialize(successResult))
                        success(result)
                    } catch {
                        fail(self.jsonParsingErrorMsg)
                    }
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    func postCurrentLocationSharing(_ requestBody: LsDataRequest, success: @escaping SuccessResult<LsDataResponse>, fail: @escaping ErrorResult) {
        do {
            var request = try URLRequest(url: CURRENT_LOCATION_SHARING_URL, method: .post, headers: header)
            request.httpBody = try JSONEncoder().encode(requestBody)
            AF.request(request).responseJSON { response in
                guard let currentLocationSharingStatusCode = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-B1", code: currentLocationSharingStatusCode, msg: "현재 위치 공유")
                switch response.result {
                case .success(let successResult) :
                    do {
                        let result = try JSONDecoder().decode(LsDataResponse.self, from: self.jsonSerialize(successResult))
                        success(result)
                    } catch {
                        fail(self.jsonParsingErrorMsg)
                    }
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    // 목적지 설정
    func postSetDestination(_ requestBody: SetDestRequest, success: @escaping SuccessResult<String>, fail: @escaping ErrorResult) {
        do {
            var request = try URLRequest(url: SET_DESTINATION_URL, method: .post, headers: header)
            request.httpBody = try JSONEncoder().encode(requestBody)
            AF.request(request).responseJSON { response in
                guard let setDestinationStatusCode = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-C", code: setDestinationStatusCode, msg: self.msg)
                switch response.result {
                case .success :
                    success("Network Success")
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    // 위치 공유 취소
    func postLocationSharingCancel(success: @escaping SuccessResult<String>, fail: @escaping ErrorResult) {
        do {
            let request = try URLRequest(url: LOCATION_SHARING_CANCEL_URL, method: .post, headers: header)
            AF.request(request).responseJSON { response in
                guard let sharingCancelStatusCode = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-D", code: sharingCancelStatusCode, msg: "위치 공유 취소")
                switch response.result {
                case .success :
                    success("Network Success")
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    // 위치 공유 수신자 명단 업데이트
    func postLocationSharingRecipientListUpdate(_ requestBody: LsListRequest, success: @escaping SuccessResult<LsListResponse>, fail: @escaping ErrorResult) {
        do {
            var request = try URLRequest(url: LOCATION_SHARING_RECIPIENT_LIST_UPDATE_URL, method: .post, headers: header)
            request.httpBody = try JSONEncoder().encode(requestBody)
            AF.request(request).responseJSON { response in
                guard let listUpdateStatusCode = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-G1", code: listUpdateStatusCode, msg: self.msg)
                switch response.result {
                case .success(let successResult) :
                    do {
                        let result = try JSONDecoder().decode(LsListResponse.self, from: self.jsonSerialize(successResult))
                        success(result)
                    } catch {
                        fail(self.jsonParsingErrorMsg)
                    }
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    // 공유 시간 연장
    func postLocationSharingTimeExtend(_ requestBody: LocationSharingExtendRequest, success: @escaping SuccessResult<TimeInterval>, fail: @escaping ErrorResult) {
        do {
            var request = try URLRequest(url: LOCATION_SHARING_TIME_EXTEND_URL, method: .post, headers: header)
            request.httpBody = try JSONEncoder().encode(requestBody)
            AF.request(request).responseJSON { response in
                guard let sharingTimeExtend = response.response?.statusCode else {
                    fail(response.description)
                    return
                }
                self.logAppend(name: "LSC-2-H", code: sharingTimeExtend, msg: "공유 시간 연장")
                switch response.result {
                case .success(let successResult) :
                    do {
                        let result = try JSONDecoder().decode(TimeInterval.self, from: self.jsonSerialize(successResult))
                        success(result)
                    } catch {
                        fail(self.jsonParsingErrorMsg)
                    }
                case .failure(let failResult) :
                    fail(failResult.localizedDescription)
                }
            }
        } catch {
            fail(networkErrorMsg)
        }
    }
    
    func setHandler(_ handler: @escaping (()-> Void)) {
        self.handler = handler
    }
}
