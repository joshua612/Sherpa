//
//  RouteViewController.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/26.
//

import UIKit
import MapKit

enum RouteViewModeType {
    case bookmark
    case noDest
    case hasDest
    case showRoute
}

class RouteViewController: UIViewController {
    
    @IBOutlet weak var destSearchBar: UISearchBar!
    
    @IBOutlet weak var bookmarkTableView: UITableView!
    @IBOutlet weak var routeMapView: MKMapView!
    @IBOutlet weak var mapModeCase: UIView!
    
    @IBOutlet weak var destModeStackView: UIStackView!
    @IBOutlet weak var waypointCase: UIView!
    @IBOutlet weak var routeModeStackView: UIStackView!
    
    @IBOutlet weak var bookmarkButton: UIButton!
    
    @IBOutlet weak var destSetBtn: UIButton!
    @IBOutlet weak var waypointSetBtn: UIButton!
    @IBOutlet weak var addBookmarkBtn: UIButton!
    
    @IBOutlet weak var startRouteBtn: UIButton!
    @IBOutlet weak var setWaypointBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var distLeft: DistanceType?
    var timeLeft: TimeInterval?
    
    var isBookmarkMode = true {
        didSet {
            if isBookmarkMode {
                bookmarkButton.setImage(UIImage(systemName: "map"), for: .normal)
            } else {
                bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            }
           checkMode()
        }
    }
    
    var isRouteMode = false {
        didSet {
            checkMode()
        }
    }
    
    var bookmarks: [Bookmark]! {
        didSet {
            self.bookmarkTableView.reloadData()
        }
    }
    
    var searchingPlace: Place?
    
    var pins: [MKAnnotation] = [MKAnnotation]()
    var overlays: [MKOverlay] = [MKOverlay]()
    // 목적지
    var destinationPlace: Place?
    // 경유지
    var waypointPlaces: [Place]?
    
    var destAndWayPlace: [Place]? {
        guard let dest = destinationPlace else {return nil}
        
        var places = [Place]()
        places.append(dest)
        
        guard let ways = waypointPlaces else {
            return places
        }
        
        places.append(contentsOf: ways)
        return places
    }
    
    var routes: [MKRoute]?
    
    var myLocationCoord: CLLocationCoordinate2D!
    
    var loading: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        bookmarks = CoreDataManager.shared.getBookmarks()
        destSearchBar.setTopbarShadow()
        myLocationCoord = LSCManager.shared.myGPSDetail!.coord.toCLCoord()
        setBtnRound()
        routeMapView.setCenter(myLocationCoord, animated: false)
        setLongPressOnTable(bookmarkTableView, action: #selector(deleteBookmark))
    }
    
    @objc func deleteBookmark(_ gestRecognizer: UILongPressGestureRecognizer) {
        if gestRecognizer.state == .began {
            let point = gestRecognizer.location(in: self.bookmarkTableView)
            guard let index = self.bookmarkTableView.indexPathForRow(at: point)?.row else {return}
            
            let bookmark = bookmarks[index]
            
            showDoubleAlert(title: "즐겨찾기 삭제", message: "선택하신 \(String(describing: bookmark.name!)) 위치를 즐겨찾기에서 삭제 하시겠습니까?", confirmHandler: { _ in
                if CoreDataManager.shared.deleteBookmark(bookmark) {
                    self.bookmarks = CoreDataManager.shared.getBookmarks()
                } else {
                    print("FAil")
                }
            }, cancelHandler: nil)
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        dismiss(animated: true)
    }
    @IBAction func bookmarkButtonClicked(_ sender: Any) {
        isBookmarkMode = !isBookmarkMode
    }
    
    @IBAction func destSetButtonClicked(_ sender: Any) {
        guard let place = searchingPlace else {
            showSingleAlert(title: nil, message: "목적지를 설정해주세요.", buttonLabel: "확인", handler: nil)
            return
        }
        
        loading = displayLoading(false)
        destinationPlace = place
        place.waypointID = 0
        // 목적지를 가지고 경로 계산
        getRoute {
            self.setRouteMode()
        }
    }
    
    @IBAction func waypointButtonClicked(_ sender: Any) {
        if waypointPlaces == nil {
            waypointPlaces = [Place]()
        }
        
        guard let place = searchingPlace else {return}
        let result = destAndWayPlace!.contains {
            $0.name == place.name && $0.address == place.address
        }
        
        if result {
            // 이미 추가된 경로입니다.
            showSingleAlert(title: nil, message: "이미 추가된 목적지입니다.", buttonLabel: "확인", handler: nil)
            return
        }
        
        loading = displayLoading(false)
        waypointPlaces!.append(place)
        place.waypointID = 1
        // 목적지를 가지고 경로 계산
        getRoute {
            self.setRouteMode()
        }
    }
    
    func setRouteMode() {
        clearMapView()
        if let routes = routes {
            routes.forEach({ route in
                routeMapView.addOverlay(route.polyline)
            })
        }
        
        isRouteMode = true
        setMode(.showRoute)
        setPinOnDest()
        
        if let view = self.loading {
            self.removeLoading(view)
        }
    }
    
    @IBAction func bookmarkAddButtonClicked(_ sender: Any) {
        guard let place = searchingPlace else {
            showSingleAlert(title: nil, message: "목적지가 없습니다.", buttonLabel: "닫기", handler: nil)
            return
        }
        
        let result = bookmarks.contains { bookmark -> Bool in
            return bookmark.name == place.name && bookmark.address == place.address
        }
        
        if result {
            showSingleAlert(title: nil, message: "이미 등록된 장소입니다.", buttonLabel: "확인", handler: nil)
            return
        }
        
        if CoreDataManager.shared.saveBookmarks(name: place.name, address: place.address, latitude: place.coord.latitude, longitude: place.coord.longitude) {
            showSingleAlert(title: "즐겨찾기 추가", message: "즐겨찾기에 추가되었습니다.", buttonLabel: "확인", handler: nil)
            bookmarks = CoreDataManager.shared.getBookmarks()
        }
    }
    
    // 경로 안내 시작
    @IBAction func routeGuideStartButtonClicked(_ sender: Any) {
        guard let dest = destinationPlace?.toLocInfoForDest(distLeft: self.distLeft!, timeLeft: self.timeLeft!) else {return}
        // 서버에 위치 전송
        if LSCManager.shared.routeCount == 0 {
            NetworkManager.shared.msg = "목적지 설정"
            LSCManager.shared.routeCount = 1
        } else {
            NetworkManager.shared.msg = "목적지 변경"
        }
        var destinations = [LocInfo]()
        destinations.append(dest)
        
        if let waypoints = waypointPlaces?.map({ place -> LocInfo in
            return place.toLocInfo(1)
        }){
            destinations.append(contentsOf: waypoints)
        }
        
        LSCManager.shared.destination.append(contentsOf: destinations)
        LSCManager.shared.routes = routes
        LSCManager.shared.totalDistLeft = self.distLeft
        LSCManager.shared.totalTimeLeft = self.timeLeft
        setRouteForMain(true)
        
            NetworkManager.shared.postSetDestination(SetDestRequest(vehicleLoc: LSCManager.shared.myGPSDetail!,
                                                                    destination: [destinations.removeFirst()],
                                                                    ignStatus: 1,
                                                                    destStatus: 1,
                                                                    wayPointInfo: destinations))
            { succeedResult in
                print(succeedResult)
                self.dismiss(animated: true)
            } fail: { failResult in
                print(failResult)
            }
    }
    
    // 경유지 추가
    @IBAction func routeAddWaypointButtonClicked(_ sender: Any) {
        setMode(.bookmark)
    }
    
    @IBAction func routeCancelButtonClicked(_ sender: Any) {
        destinationPlace = nil
        waypointPlaces = nil
        setMode(.noDest)
        showPlace(searchingPlace!)
        clearMapView()
        searchingPlace = nil
    }
}

extension RouteViewController {
    func setBtnRound() {
        destSetBtn.setDefaultRound()
        waypointSetBtn.setDefaultRound()
        addBookmarkBtn.setDefaultRound()
        startRouteBtn.setDefaultRound()
        setWaypointBtn.setDefaultRound()
        cancelBtn.setDefaultRound()
    }
    
    func setRouteForMain(_ isExist: Bool) {
        if let vc = presentingViewController as? MainViewController {
            vc.setRoute(isExist)
        }
    }
    
    func checkMode() {
        if isBookmarkMode {
            setMode(.bookmark)
            return
        }
        
        guard let _ = destinationPlace,
              let _ = routes else {
            setMode(.noDest)
            return
        }
        
        if isRouteMode {
            setMode(.showRoute)
        } else {
            setMode(.hasDest)
        }
    }
    
    func setMode(_ mode: RouteViewModeType) {
        switch mode {
        case .bookmark:
            mapModeCase.hide()
            bookmarkTableView.show()
        case .noDest:
            mapModeCase.show()
            bookmarkTableView.hide()
            destModeStackView.show()
            waypointCase.hide()
            routeModeStackView.hide()
        case .hasDest:
            mapModeCase.show()
            bookmarkTableView.hide()
            destModeStackView.show()
            waypointCase.show()
            routeModeStackView.hide()
        case .showRoute:
            mapModeCase.show()
            bookmarkTableView.hide()
            destModeStackView.hide()
            routeModeStackView.show()
        }
    }
    
    func getRoute(_ handler: @escaping () -> Void) {
        clearMapOverlays()
        
        guard let dest = destinationPlace else {return}
        
        var lastCoord: CLLocationCoordinate2D = myLocationCoord
        
        var indexingRoutes = [(Int, MKRoute)]()
        
        var destAndWay = [Place]()
        if let way = waypointPlaces {
            destAndWay = way
        }
        destAndWay.append(dest)
        
        for (index,place) in destAndWay.enumerated() {
            let nextCoord = place.coord
            getDirection(index, startCoord: lastCoord, endCoord: nextCoord) { (index, route) in
                guard let route = route else {
                    self.showSingleAlert(title: nil, message: "경로를 찾을 수 없습니다.", buttonLabel: "확인", handler: nil)
                    return
                }
                indexingRoutes.append((index, route))
                
                if indexingRoutes.count == destAndWay.count {
                    indexingRoutes.sort {
                        $0.0 < $1.0
                    }
                    
                    self.routes = [MKRoute]()
                    
                    var totalDistance: Double = 0
                    var totalExpectedTravalTime: Double = 0
                    
                    indexingRoutes.forEach { (index, route) in
                        totalDistance += route.distance
                        totalExpectedTravalTime += route.expectedTravelTime
                        self.routes!.append(route)
                    }
                    
                    self.distLeft = DistanceType(value: totalDistance, unit: 2)
                    self.timeLeft = TimeInterval(value: Int(totalExpectedTravalTime), unit: 3)
                    handler()
                }
            }
            lastCoord = nextCoord
        }
    }
    
    func clearMapView() {
        clearMapAnnotions()
        clearMapOverlays()
    }
    
    func clearMapAnnotions() {
        routeMapView.removeAnnotations(pins)
    }
    
    func clearMapOverlays() {
        routeMapView.removeOverlays(routeMapView.overlays)
        overlays.removeAll()
    }
    
    func setPinOnDest() {
        clearMapAnnotions()
        guard let daw = destAndWayPlace else {return}
        daw.forEach {makePin($0)}
    }
    
    func makePin(_ place: Place) {
        // 핀 찍기
        let pin = SearchPin(waypointID: place.waypointID)
        pin.coordinate = place.coord
        pin.title = place.name
        routeMapView.addAnnotation(pin)
        pins.append(pin)
    }
}

extension RouteViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlays.contains(where: {$0 === overlay}) {return MKOverlayRenderer()}
        overlays.append(overlay)
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = .cyan
        render.lineWidth = 5
        let edge: CGFloat = 50
        mapView.setVisibleMapRect(overlay.boundingMapRect, edgePadding: UIEdgeInsets(top: edge, left: edge, bottom: edge, right: edge), animated: true)
        return render
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard let annotation = annotation as? SearchPin else { return nil }
        
        let identifier = "Pin"
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        switch annotation.waypointID {
        case 0:
            annotationView.image = UIImage(named: "Flag.png")
        case 1:
            annotationView.image = UIImage(named: "WaypointFlag.png")
        default:
            annotationView.image = UIImage(named: "SearchPin.png")
        }
        return annotationView
    }
}

extension RouteViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchFromName(searchBar.text!)
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchFromName(_ name: String) {
        let losere = MKLocalSearch.Request()
        losere.region = routeMapView.region
        losere.naturalLanguageQuery = name
        
        let se = MKLocalSearch(request: losere)
        se.start { (response, error) in
            if let _ = error {
                return
            }
            
            guard let response = response else {return}
            
            let coord = response.boundingRegion.center
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { (placemark, error) in
                guard let mark = placemark, let place = mark.first else {return}
                
                var address: String = ""
                if let area = place.administrativeArea {
                    address += area
                }
                if let locality = place.locality {
                    address += " \(locality)"
                }
                if let subLocality = place.subLocality {
                    address += "-\(subLocality)"
                }
                self.showPlace(Place(waypointID:2, name: name, address: address, coord: response.boundingRegion.center))
            }
        }
    }
    
    func showPlace(_ place: Place) {
        clearMapAnnotions()
        isBookmarkMode = false
        isRouteMode = false
        searchingPlace = place
        makePin(searchingPlace!)
        let region = MKCoordinateRegion(center: place.coord, latitudinalMeters: 500, longitudinalMeters: 500)
        self.routeMapView.setRegion(region, animated: false)
        checkMode()
    }
}

extension RouteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bookmark = bookmarks[indexPath.row]
        showPlace(Place(waypointID: 2, name: bookmark.name!, address: bookmark.address!, coord: CLLocationCoordinate2DMake(bookmark.latitude, bookmark.longitude)))
    }
}

extension RouteViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RouteBookmarkCell", for: indexPath) as? RouteBookmarkCell else {
            return UITableViewCell()
        }
        cell.setBookmarkData(bookmarks[indexPath.row])
        return cell
    }
}

class Place {
    var waypointID: Int
    let name: String
    let address: String
    let coord: CLLocationCoordinate2D
    
    init(waypointID: Int, name: String, address: String, coord: CLLocationCoordinate2D) {
        self.waypointID = waypointID
        self.name = name
        self.address = address
        self.coord = coord
    }
    
    func toLocInfo(_ waypointID: Int?) -> LocInfo {
        var info = LocInfo(addr: self.address, name: self.name, coord: self.coord)
        info.waypointID = waypointID
        return info
    }
    
    func toLocInfoForDest(distLeft: DistanceType, timeLeft: TimeInterval) -> LocInfo {
        let info = LocInfo(addr: self.address, name: self.name, coord: Coord(self.coord), waypointID: 0, distLeft: distLeft, timeLeft: timeLeft)
        return info
    }
}

class SearchPin: MKPointAnnotation {
    var waypointID: Int
    
    init(waypointID: Int) {
        self.waypointID = waypointID
    }
}
