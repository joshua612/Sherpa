//
//  ViewController.swift
//  Sherpa
//
//  Created by 전현성 on 2021/03/03.
//

import UIKit
import MapKit
import CoreLocation

private let myPinTitle = "myPin"
private let destPinTitle = "destPin"
private let waypointPinTitle = "waypointPin"

class MainViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var myLocationBtn: UIButton!
    @IBOutlet weak var goStopBtn: UIButton!
    
    @IBOutlet weak var destCancelBtn: UIButton!
    @IBOutlet weak var setRouteBtn: UIButton!
    @IBOutlet weak var shareLocationBtn: UIButton!
    @IBOutlet weak var showLogBtn: CircleButton!
    @IBOutlet weak var changeIDBtn: CircleButton!
    
    @IBOutlet weak var destCancelBtnY: NSLayoutConstraint!
    @IBOutlet weak var setRouteBtnY: NSLayoutConstraint!
    @IBOutlet weak var shareLocationBtnY: NSLayoutConstraint!
    @IBOutlet weak var showLogBtnY: NSLayoutConstraint!
    @IBOutlet weak var changeIDBtnX: NSLayoutConstraint!
    
    @IBOutlet weak var logTableView: UITableView!
    @IBOutlet weak var logClearBtn: UIButton!
    @IBOutlet weak var boostLevelLabel: UILabel!
    @IBOutlet weak var boostSlowBtn: UIButton!
    @IBOutlet weak var boostFastBtn: UIButton!
    @IBOutlet weak var boostLevelCase: UIView!
    @IBOutlet weak var changeIDCase: UIView!
    
    @IBOutlet weak var nadIDLabel: UILabel!
    @IBOutlet weak var vinLabel: UILabel!
    
    var loading: UIView?
    var isFirst = true
    var isMenuOpened = false
    var isLogShowing = true
    var isChangeIDCaseShowing = false {
        didSet {
            changeIDCase.isHidden = !isChangeIDCaseShowing
        }
    }
    var myPinView: MKAnnotationView!
    var mapViewCameraHeading: CLLocationDirection = 0
    let routeStoryBoard: UIStoryboard = UIStoryboard(name: "Route", bundle: nil)
    let contactStoryBoard: UIStoryboard = UIStoryboard(name: "Contact", bundle: nil)
    
    var destCoord = DEFAULT_DESTINATION
    let mapCalculator = MapCalculator()
    
    var boostLevel = 1 {
        didSet {
            boostLevelLabel.text = String(boostLevel)
        }
    }
    var boostLevelRate: Double = 1
    
    let myPin: MKPointAnnotation = {
        let annotation = MKPointAnnotation()
        annotation.title = myPinTitle
        
        return annotation
    }()
    
    let destPin: MKPointAnnotation = {
        let annotation = MKPointAnnotation()
        annotation.title = destPinTitle
        
        return annotation
    }()
    
    var pins: [MKAnnotation] = [MKAnnotation]()
    
    var waypointPins = [CLLocationCoordinate2D]()
    
    var routeCoordinates = [CLLocationCoordinate2D]()
    var coordinateIndex: Int!
    
    var totalRouteDistance: Double {
        return LSCManager.shared.totalDistLeft!.value!
    }
    var totalRouteDistLeft: DistanceType {
        return DistanceType(value: totalRouteDistance - (moveDistancePerSec * moveTimeSec), unit: 2)
    }
    
    var totalExpectedTravelTime: Double {
        return Double(LSCManager.shared.totalTimeLeft!.value)
    }
    var totalExpectedTravalTimeLeft: TimeInterval {
        return TimeInterval(value: Int(totalExpectedTravelTime - moveTimeSec)/Int(boostLevelRate), unit: 3)
    }
    
    var moveTimeSec: Double = 0
    var moveDistancePerSec: Double!
    
    var sectionDistance: Double!
    var sectionDistanceLeft: Double!
    
    var myLocationCoord: CLLocationCoordinate2D!
    var destPinCoord: CLLocationCoordinate2D!
    
    var heading: Double = 0
    var preHeading: Double = 0
    var speed: Double = 0
    
    var myLocationGPSDatas = [GPSDetail]()
    
    var routes: [MKRoute]! {
        didSet {
            moveStop()
        }
    }
    
    var isDriving = false
    
    //MARK: Var for Calc
    var remainDistanceInLastSection: Double = 0
    var stepCoord: (Double, Double)!
    
    var stackGPSDataTimer: DispatchSourceTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTableView.hide()
        logClearBtn.hide()
        logClearBtn.setDefaultRound()
        myLocationCoord = DEFAULT_START_POINT
        startStackGPSDataTimer()
        setRouteOnMap()
        setDefaultPin()
        mapView.setCenter(myLocationCoord, animated: false)
        NetworkManager.shared.setHandler{
            self.logTableView.reloadData()
            self.scrollToBottom()
        }
        
        boostLevelCase.setDefaultRound()
        setUUData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isFirst {
            loading = displayLoading(false)
            isFirst = false
        }
        if LSCManager.shared.isSharing {
            self.shareLocationBtn.titleLabel?.textColor = .systemIndigo
        } else {
            self.shareLocationBtn.titleLabel?.textColor = .white
        }
    }
    
    @IBAction func myLocationBtn(_ sender: Any) {
        let region = MKCoordinateRegion(center: myLocationCoord , latitudinalMeters: 500, longitudinalMeters: 500)
        self.mapView.setRegion(region, animated: true)
    }
    
    @IBAction func goStopBtn(_ sender: Any) {
        if isDriving {
            moveStop()
        } else {
            moveStart()
        }
    }
    
    @IBAction func shareLocationBtn(_ sender: Any) {
        if LSCManager.shared.isSharing {
            guard let shareVC = self.contactStoryBoard.instantiateViewController(withIdentifier: "ContactViewController") as? ContactViewController  else { return }
            self.present(shareVC, animated: true)
        } else {
            shareStart()
        }
    }
    
    
    @IBAction func setDestBtn(_ sender: Any) {
        guard let routeVC = routeStoryBoard.instantiateViewController(withIdentifier: "RouteViewController") as? RouteViewController else { return }
        present(routeVC, animated: true)
    }
    
    @IBAction func destCancelBtn(_ sender: Any) {
        NetworkManager.shared.msg = "목적지 취소"
        LSCManager.shared.routeCount = 0
        loading = displayLoading(false)
        destStatusChange(status: 0)
        setRoute(false)
    }
    
    @IBAction func menuBtnClicked(_ sender: Any) {
        let rotation: CGFloat = isMenuOpened ? 0 : .pi
        if isMenuOpened {
            closeMenu()
            isMenuOpened = false
        } else {
            openMenu(-(sender as! UIView).frame.height - 10)
            isMenuOpened = true
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.7, options: .curveEaseOut) {
            (sender as! UIButton).transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    @IBAction func showLogBtnClicked(_ sender: Any) {
        if isChangeIDCaseShowing {
            isChangeIDCaseShowing = false
        }
        
        if isLogShowing {
            logTableView.hide()
            logClearBtn.hide()
            isLogShowing = false
        } else {
            logTableView.show()
            logClearBtn.show()
            isLogShowing = true
        }
    }
    
    @IBAction func changeIDBtnClicked(_ sender: Any) {
        if isLogShowing {
            logTableView.hide()
            logClearBtn.hide()
            isLogShowing = !isLogShowing
        }
        
        isChangeIDCaseShowing = !isChangeIDCaseShowing
    }
    
    @IBAction func changeBtnClicked(_ sender: Any) {
        let msg: String = LSCManager.shared.isSharing ? "NADID를 갱신할 시 공유 서비스가 종료됩니다." : "NADID를 갱신하시겠습니까?"
        showDoubleAlert(title: "NADID 갱신", message: msg, confirmHandler: { _ in
            if LSCManager.shared.isSharing {
                NetworkManager.shared.postLocationSharingCancel { _ in
                    LSCManager.shared.isSharing = false
                    self.changeUUData()
                } fail: { _ in
                    self.showSingleAlert(title: "공유 취소 실패", message: "위치 공유 취소에 실패하였습니다.", buttonLabel: "확인", handler: nil)
                }

            } else {
                self.changeUUData()
            }
        }, cancelHandler: nil)
    }
    
    @IBAction func logClearBtnClicked(_ sender: Any) {
        NetworkManager.shared.logs.removeAll()
    }
    
    @IBAction func speedUpClicked(_ sender: Any) {
        if boostLevel >= 5 {
            return
        }
        boostLevel += 1
        boostLevelRate *= 4
    }
    @IBAction func speedDownClicked(_ sender: Any) {
        if boostLevel <= 1 {
            return
        }
        boostLevel -= 1
        boostLevelRate /= 4
    }
}

extension MainViewController {
    func setUUData() {
        if let data = CoreDataManager.shared.getUUData() {
            NetworkManager.shared.uuData = data
        } else {
            let newData = createUUData()
            guard let data = newData else {return}
            NetworkManager.shared.uuData = data
        }
        nadIDLabel.text = NetworkManager.shared.uuData.nadID
        vinLabel.text = NetworkManager.shared.uuData.vin
    }
    
    func createNadIDAndVin()-> (String, String) {
        let uuid: String
        if let id = UIDevice.current.identifierForVendor?.uuidString {
            uuid = id
        } else {
            uuid = ""
        }
        
        let currentTime = String(Date().timeIntervalSince1970)
        let nadID = String(uuid[uuid.startIndex...uuid.index(uuid.startIndex, offsetBy: 6)] + currentTime[currentTime.index(currentTime.endIndex, offsetBy: -4)..<currentTime.endIndex])
        let vin = "SHERPA" + nadID
        return (nadID, vin)
    }
    
    func createUUData()-> UUData? {
        let result = createNadIDAndVin()
        guard CoreDataManager.shared.saveUUData(nadID: result.0, vin: result.1) else {return nil}
        return CoreDataManager.shared.getUUData()
    }
    
    func changeUUData() {
        let result = createNadIDAndVin()
        NetworkManager.shared.uuData.nadID = result.0
        NetworkManager.shared.uuData.vin = result.1
        
        if CoreDataManager.shared.save() {
            nadIDLabel.text = NetworkManager.shared.uuData.nadID
            vinLabel.text = NetworkManager.shared.uuData.vin
        } else {
            print("UU Error")
        }
    }
    
    func shareStart() {
        NetworkManager.shared.postLocationSharingStart(LSCManager.shared.lsStartRequestData) { _ in
            print("share Start")
            LSCManager.shared.isSharing = true
            guard let shareVC = self.contactStoryBoard.instantiateViewController(withIdentifier: "ContactViewController") as? ContactViewController  else { return }
            self.present(shareVC, animated: true)
        } fail: { msg in // 위치 공유 시작 단계에서 공유 실패
            self.showSingleAlert(title: msg, message: "위치 공유 설정에 실패하였습니다.", buttonLabel: "확인", handler: nil)
         }
    }
    
    func setDefaultPin() {
        myPin.coordinate = DEFAULT_START_POINT
        self.mapView.addAnnotation(self.myPin)
    }
    
    func moveStart() {
        isDriving = true
        self.goStopBtn.setTitle("STOP", for: .normal)
        calcSection()
    }
    
    func moveStop() {
        isDriving = false
        self.goStopBtn.setTitle("GO", for: .normal)
    }
    
    func arrivalDest() {
        if mapCalculator.getDistanceFromCoord(sectionStartCoord: myLocationCoord, sectionEndCoord: DEFAULT_DESTINATION) < 500 {
            destCoord = DEFAULT_START_POINT
        } else {
            destCoord = DEFAULT_DESTINATION
        }
        destStatusChange(status: 2)
        moveStop()
        loading = displayLoading(true)
        self.setRoute(false)
        boostLevel = 1
        boostLevelRate = 1
    }
    
    // 경로 설정 및 좌표 얻어옴
    func getDefaultRoute() {
        let startPoint = MKPlacemark(coordinate: myLocationCoord)
        let destPoint = MKPlacemark(coordinate: destCoord)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: startPoint)
        directionRequest.destination = MKMapItem(placemark: destPoint)
        directionRequest.transportType = .automobile
        
        let direction = MKDirections(request: directionRequest)
        
        direction.calculate(completionHandler: {response, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let route = response?.routes.first else {
                self.showSingleAlert(title: nil, message: "경로를 찾을 수 없습니다.", buttonLabel: "확인", handler: nil)
                return
            }
            
            LSCManager.shared.totalDistLeft = DistanceType(value: route.distance, unit: 2)
            LSCManager.shared.totalTimeLeft = TimeInterval(value: route.expectedTravelTime, unit: 3)
            LSCManager.shared.routes = [route]
            self.setRouteOnMap()
        })
    }
    
    func makePin() {
        self.myLocationCoord = self.routeCoordinates.first!
        self.myPin.coordinate = self.myLocationCoord
        
        let destinations = LSCManager.shared.destination
        destinations.forEach { dests in
            if dests.waypointID == 1 {
                // 경유지 좌표
                let wayPin = MKPointAnnotation()
                wayPin.coordinate = CLLocationCoordinate2DMake(dests.coord.lat, dests.coord.lon)
                wayPin.title = waypointPinTitle
                mapView.addAnnotation(wayPin)
                pins.append(wayPin)
            } else {
                // 목적지 좌표
                let destPin = MKPointAnnotation()
                destPin.coordinate = CLLocationCoordinate2DMake(dests.coord.lat, dests.coord.lon)
                destPin.title = destPinTitle
                mapView.addAnnotation(destPin)
                pins.append(destPin)
            }
        }
    }
    
    func setRouteOnMap() {
        guard let routes = LSCManager.shared.routes else {
            // 경로가 없을 경우 기본 경로로 진행
            getDefaultRoute()
            return
        }
        
        self.routes = routes
        self.routeCoordinates = [CLLocationCoordinate2D]()
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(pins)
        
        self.routes.forEach { route in
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            self.routeCoordinates.append(contentsOf: route.polyline.coordinates)
        }
        
        self.speed = self.mapCalculator.calcSpeed(secTime: self.totalExpectedTravelTime, distance: self.totalRouteDistance)
        self.moveDistancePerSec = self.totalRouteDistance / self.totalExpectedTravelTime
        makePin()
        self.mapView.setRegion(MKCoordinateRegion(center: self.myLocationCoord, latitudinalMeters: 500, longitudinalMeters: 500), animated: false)
        
        self.coordinateIndex = 0
        if let view = self.loading {
            self.removeLoading(view)
            boostLevel = 1
            boostLevelRate = 1
        }
    }

    func stackMyGPSData() {
        let velocity = isDriving ? speed * Double(boostLevelRate) : 0
        let coord = Coord(myLocationCoord, alt: 34, heading: heading, velocity: velocity)
        let myGPSData = GPSDetail(coord: coord,
                                  head: Int(heading),
                                  speed: Velocity(value: Int(velocity), unit: 0),
                                  accuracy: Accuracy(hdop: 4, pdop: 4),
                                  time: mapCalculator.getCurrentTime())
        
        // 데이터 적재
        LSCManager.shared.myGPSDetail = myGPSData
//        print("my location is \(self.myLocationCoord.latitude)/\(self.myLocationCoord.longitude)")
        myLocationGPSDatas.append(myGPSData)
        if myLocationGPSDatas.count >= 10 {
            if LSCManager.shared.isSharing {
                let distLeft: DistanceType?
                let timeLeft: TimeInterval?
                if LSCManager.shared.isRouteExist {
                    distLeft = totalRouteDistLeft
                    timeLeft = totalExpectedTravalTimeLeft  // TODO
                } else {
                    distLeft = nil
                    timeLeft = nil
                }
                if let dl = distLeft, let tl = timeLeft {
                    print("LSC-2-B1 spped : \(myLocationGPSDatas.last!.speed.value) / moveTime = \(moveTimeSec)/ distLeft: \(Int(dl.value!))m / timeLeft: \(tl.value)sec")
                }
                NetworkManager.shared.postCurrentLocationSharing(LsDataRequest(currentLocation: myLocationGPSDatas,
                                                                               distLeft: distLeft,
                                                                               timeLeft: timeLeft))
                { response in
                    // 연락처 상태 갱신
                    guard let list = response.locShareAckList else {
                        LSCManager.shared.sharedContacts?.forEach({ contact in
//                            contact.status = .none
                        })
                        return
                    }
                    
                    LSCManager.shared.sharedContacts?.forEach({ commonContact in
                        if list.contains(where: { ack -> Bool in
                            return ack.phoneNum.korTypeToPhoneNum() == commonContact.phoneNum
                        }) {
                            commonContact.status = .sharing
                        }
                    })
                    
                } fail: { failMsg in
                    print(failMsg)
                }
            }
            myLocationGPSDatas.removeAll()
        }
    }
    
    func setRoute(_ isExist: Bool) {
        moveTimeSec = 0
        LSCManager.shared.isRouteExist = isExist
        destCancelBtn.isHidden = !LSCManager.shared.isRouteExist
        routes = LSCManager.shared.routes
        setRouteOnMap()
    }
    
    func destStatusChange(status: Int) {
        var dests = LSCManager.shared.destination
        if dests.first == nil {return}
        NetworkManager.shared.postSetDestination(SetDestRequest(vehicleLoc: LSCManager.shared.myGPSDetail!,
                                                                destination: [dests.removeFirst()],
                                                                ignStatus: 1,
                                                                destStatus: status,
                                                                wayPointInfo: dests))
            { succeedResult in
                print(succeedResult)
                self.dismiss(animated: true)
            } fail: { failResult in
                print(failResult)
            }
    }
}

extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard overlay is MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = LSCManager.shared.isRouteExist ? .cyan : .clear
        renderer.lineWidth = 5
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        switch annotation.title {
        case myPinTitle:
            annotationView.image = UIImage(named: "snow mobile.png")
            myPinView = annotationView
        case destPinTitle:
            annotationView.image = UIImage(named: "Flag.png")
        case waypointPinTitle:
            annotationView.image = UIImage(named: "WaypointFlag.png")
        default:
            break
        }
        return annotationView
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        if mapViewCameraHeading == mapView.camera.heading {return}
        mapViewCameraHeading = mapView.camera.heading
        rotateMyPin()
    }
}

extension MainViewController {
    func startStackGPSDataTimer() {
        stackGPSDataTimer = DispatchSource.makeTimerSource(flags: [], queue: .global(qos: .background))
        stackGPSDataTimer.schedule(deadline: .now(), repeating: 1)
        stackGPSDataTimer.setEventHandler {
            self.stackMyGPSData()
            if self.isDriving {
                self.moveTimeSec += Double(self.boostLevelRate)
            }
        }
        stackGPSDataTimer.resume()
    }
    
    // 섹션을 비교
    // 다음 섹션으로 넘어갈 시 무조건 이곳을 타도록 한다.
    func calcSection() {
        coordinateIndex += 1
        
        if coordinateIndex == routeCoordinates.count {
            arrivalDest()
            return
        }
        
        let moveDistancePerSecWithBoost = self.moveDistancePerSec * boostLevelRate
        
        self.sectionDistance = mapCalculator.getDistanceFromCoord(sectionStartCoord: myLocationCoord, sectionEndCoord: routeCoordinates[coordinateIndex])
        self.sectionDistanceLeft = sectionDistance
        
        calcHeading()
        
        let moveDistance: Double = remainDistanceInLastSection == 0 ? moveDistancePerSecWithBoost : remainDistanceInLastSection
        if sectionDistance > moveDistance {
            if moveDistance == moveDistancePerSecWithBoost {
                stepCoord = calcSectionMove(distanceToMove: moveDistancePerSecWithBoost)
            }
            prepareToMove(distance: moveDistance)
        } else {
            prepareToMove(distance: sectionDistance)
        }
    }
    
    func calcHeading() {
        let sectionStartCoord: CLLocationCoordinate2D = myLocationCoord
        let sectionEndCoord: CLLocationCoordinate2D = routeCoordinates[coordinateIndex]
        
        let latGap = sectionStartCoord.latitude - sectionEndCoord.latitude
        let lonGap = sectionStartCoord.longitude - sectionEndCoord.longitude
        
        heading = mapCalculator.calcHeading(laGap: latGap, loGap: lonGap)
        rotateMyPin()
    }
    
    //MARK: Common
    func calcSectionMove(distanceToMove: Double)-> (Double, Double) {
        let sectionStartCoord: CLLocationCoordinate2D = myLocationCoord
        let sectionEndCoord: CLLocationCoordinate2D = routeCoordinates[coordinateIndex]
        let moveCount = sectionDistance / distanceToMove
        
        let latGap = sectionStartCoord.latitude - sectionEndCoord.latitude
        let lonGap = sectionStartCoord.longitude - sectionEndCoord.longitude
    
        let moveLatSec = latGap / moveCount
        let moveLonSec = lonGap / moveCount
        
        return (moveLatSec, moveLonSec)
    }
    
    func prepareToMove(distance: Double!) {
        if distance == 0 {
            calcSection()
            return
        }
        
        let moveDistancePerSecWithBoost = self.moveDistancePerSec * boostLevelRate
        // 희망 이동거리만큼 움직일수 있는지 확인
        // 없다면 남은 거리만큼 움직이고, 잔여거리 남겨둔 뒤 다음 섹션으로 이동
        if distance >= sectionDistanceLeft {
            remainDistanceInLastSection = distance - sectionDistanceLeft
            let duration = sectionDistanceLeft / moveDistancePerSecWithBoost
            moveTo(routeCoordinates[coordinateIndex], distance: sectionDistanceLeft, duration: duration, next: self.calcSection)
            return
        }
        // 있다면?
        // 근데 희망 거리가 잔여거리 라면?
        if distance < moveDistancePerSecWithBoost {
            let remainStepCoord = calcSectionMove(distanceToMove: remainDistanceInLastSection)
            let duration = remainDistanceInLastSection / moveDistancePerSecWithBoost
            let nextCoord = CLLocationCoordinate2DMake(myLocationCoord.latitude - remainStepCoord.0, myLocationCoord.longitude - remainStepCoord.1)
            moveTo(nextCoord, distance: remainDistanceInLastSection, duration: duration) {
                self.remainDistanceInLastSection = 0
                self.stepCoord = self.calcSectionMove(distanceToMove: moveDistancePerSecWithBoost)
                self.prepareToMove(distance: moveDistancePerSecWithBoost)
            }
            return
        }
        // 잔여거리도 아니고 일반 거리라면?
        let nextCoord = CLLocationCoordinate2DMake(myLocationCoord.latitude - stepCoord.0, myLocationCoord.longitude - stepCoord.1)
        moveTo(nextCoord, distance: moveDistancePerSecWithBoost, duration: 1) {
            self.prepareToMove(distance: moveDistancePerSecWithBoost)
        }
    }
    
    // distance : 초당 진행거리, 지난 잔여 거리, 짧은 섹션
    func moveTo(_ coord: CLLocationCoordinate2D, distance: Double, duration: Double, next: @escaping (()-> Void)) {
//        print("duration is \(duration) , distance is \(distance)")
        self.sectionDistanceLeft -= distance
        self.myLocationCoord = coord
//        self.mapView.setCenter(self.myLocationCoord, animated: true)
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.myPin.coordinate = self.myLocationCoord
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.isDriving {
                next()
            }
        }
    }
}

// UI 관련
extension MainViewController {
    func openMenu(_ gap: CGFloat) {
        destCancelBtnY.constant = gap
        setRouteBtnY.constant = gap
        shareLocationBtnY.constant = gap
        showLogBtnY.constant = gap
        changeIDBtnX.constant = -gap

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.7, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }
    
    func closeMenu() {
        destCancelBtnY.constant = 0
        setRouteBtnY.constant = 0
        shareLocationBtnY.constant = 0
        showLogBtnY.constant = 0
        changeIDBtnX.constant = 0

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }
    
    func rotateMyPin() {
        var newHeading = heading + (360 - mapView.camera.heading)
        if preHeading == newHeading {return}
        if newHeading > 360 {
           newHeading -= 360
        }
        let gap =  newHeading - getMyPinViewAngle(myPinView.transform)
        let one: CGFloat = .pi / 180
        self.myPinView.transform = self.myPinView.transform.rotated(by: CGFloat(gap) * one)
        preHeading = newHeading
    }
    
    func getMyPinViewAngle(_ transform: CGAffineTransform)-> Double {
        let radians = atan2(transform.b, transform.a)
        return Double(radians) * (180 / .pi)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NetworkManager.shared.logs.count
      }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath) as? LogCell else {
            return UITableViewCell()
        }
        cell.setLog(log: NetworkManager.shared.logs[indexPath.row])

        return cell
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async {
            if NetworkManager.shared.logs.count > 0 {
                let cnt = NetworkManager.shared.logs.count > 0 ? NetworkManager.shared.logs.count - 1 : 0
                let indexPath = IndexPath(row: cnt, section: 0)
                self.logTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
}
