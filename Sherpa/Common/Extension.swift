//
//  ViewControllerExtension.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/19.
//

import Foundation
import UIKit
import MapKit

extension UIView {
    func setDefaultRound() {
        self.layer.cornerRadius = 10
    }
    
    func setDefaultShadow() {
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 2
        self.layer.masksToBounds = false
    }
    
    func setTopbarShadow() {
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 1
        self.layer.masksToBounds = false
    }
    
    func setCircleView() {
        self.layer.cornerRadius = self.bounds.height/2
    }
    
    func show() {
        self.isHidden = false
    }
    
    func hide() {
        self.isHidden = true
    }
}

extension UIViewController {
    func getSingleAlert(title: String?, message: String?, buttonLabel: String, handler: ((UIAlertAction) -> Void)?)-> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonLabel, style: .default, handler: handler))
        return alert
    }
    
    func showSingleAlert(title: String?, message: String?, buttonLabel: String, handler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonLabel, style: .default, handler: handler))
        self.present(alert, animated: true)
    }
    
    func showDoubleAlert(title: String?, message: String?, confirmHandler: @escaping (UIAlertAction)-> Void, cancelHandler: ((UIAlertAction)-> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: confirmHandler))
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: cancelHandler))
        present(alert, animated: true)
    }
    
    func errorResultWithAlert(title: String, msg: String) {
        
    }
    
    func getDirection(_ index: Int, startCoord: CLLocationCoordinate2D, endCoord: CLLocationCoordinate2D,
                      handler: @escaping (Int, MKRoute?)-> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            if error != nil {
                handler(index, nil)
                return
            }
            guard let response = response else {
                handler(index, nil)
                return
            }
            // 경로를 빠른 순으로 정렬하여 가장 빠른 경로만 추출
            let fastestRoute = response.routes.sorted {
                $0.expectedTravelTime < $1.expectedTravelTime
            }.first
            
            guard let route = fastestRoute else {return}
            
            guard route.steps.contains(where: { // 차량 경로가 없는 경우
                $0.transportType == .automobile
            }) else {
                handler(index, nil)
                return
            }
            // 이동수단이 차량(rawValue: 1) 이 아닐 시 마지막 차량 경로까지를 목적지로 설정하여 경로 재탐색
            for step in route.steps {
                if step.transportType != .automobile {
                    self.getDirection(index, startCoord: startCoord, endCoord: step.polyline.coordinate, handler: handler)
                    return
                }
            }
            
            handler(index, route)
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setLongPressOnTable(_ table: UITableView, action: Selector) {
        let longGest = UILongPressGestureRecognizer(target: self, action: action)
        longGest.minimumPressDuration = 1.0
        table.addGestureRecognizer(longGest)
    }
}

public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        
        return coords
    }
}


extension String {
    func phoneNumToKorType ()-> String {
        if self.starts(with: "0") {
            var num = self
            num.replaceSubrange(...num.startIndex, with: "82")
            return num
        }
        return self
    }
    
    func korTypeToPhoneNum ()-> String {
        if self.starts(with: "82") {
            var num = self
            let index = num.index(num.startIndex, offsetBy: 1)
            num.replaceSubrange(...index, with: "0")
            return num
        }
        return self
    }
    
    func stringFromDate() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: now)
    }
}

extension UIViewController {
    func displayLoading(_ isArrive: Bool)-> UIView {
            let loadingCase = UIView(frame: view.frame)
            loadingCase.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            let loadingView = UIActivityIndicatorView.init(style: .large)
            loadingView.color = .white
            loadingView.center = loadingCase.center
            loadingView.startAnimating()
            loadingCase.addSubview(loadingView)
            view.addSubview(loadingCase)
    
        if isArrive {
            let arriveMessage = UILabel()
            arriveMessage.text = "목적지에 도착했습니다"
            NetworkManager.shared.msg = "목적지 도착"
            LSCManager.shared.routeCount = 0
            arriveMessage.textColor = .white
            loadingCase.addSubview(arriveMessage)
            arriveMessage.translatesAutoresizingMaskIntoConstraints = false
            arriveMessage.topAnchor.constraint(equalTo: loadingCase.topAnchor, constant: 120).isActive = true
            arriveMessage.bottomAnchor.constraint(equalTo: loadingCase.bottomAnchor, constant: 10).isActive = true
            arriveMessage.centerXAnchor.constraint(equalTo: loadingCase.centerXAnchor).isActive = true
        }
        return loadingCase
    }
    
    func removeLoading(_ loadingCase: UIView) {
        if let loadingView = loadingCase.subviews.first as? UIActivityIndicatorView {
            loadingView.stopAnimating()
        }
        loadingCase.removeFromSuperview()
    }
}
