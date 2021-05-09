//
//  ContactViewController.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/23.
//

import UIKit

class ContactViewController: UIViewController {
    @IBOutlet weak var topbar: UIView!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var shareStackView: UIStackView!
    
    @IBOutlet weak var shareCancelButton: UIButton!
    @IBOutlet weak var shareLocationBtn: UIButton!
    
    @IBOutlet weak var shareStartBtn: UIButton!
    @IBOutlet weak var shareCancelBtn: UIButton!
    
    @IBOutlet weak var timeExtensionView: UIView!
    @IBOutlet weak var timeExtensionBtn: UIButton!
    
    var contacts: [Contact]! {
        didSet {
            self.contactTableView.reloadData()
        }
    }
    
    var isShareMode = false {
        didSet {
            self.contactTableView.reloadData()
            self.shareStackView.isHidden = !isShareMode
            self.addButton.isHidden = isShareMode
            if !isShareMode {
                self.contactsCheckReset()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkShareContact()
        setBtnRound()
        topbar.setTopbarShadow()
        
        shareCancelButton.isEnabled = LSCManager.shared.isSharing
        // 기본 연릭처 획득
        contacts = CoreDataManager.shared.getContacts()
        setLongPressOnTable(contactTableView, action: #selector(deleteContact))
        checkContactState()
    }
    
    @objc func deleteContact(_ gestRecognizer: UILongPressGestureRecognizer) {
        if gestRecognizer.state == .began {
            let point = gestRecognizer.location(in: self.contactTableView)
            guard let index = self.contactTableView.indexPathForRow(at: point)?.row else {return}
            let contact = contacts[index]
            
            showDoubleAlert(title: "연락처 삭제", message: "선택하신 \(String(describing: contact.name!))님의 연락처를 삭제 하시겠습니까?", confirmHandler: { _ in
                if CoreDataManager.shared.deleteContact(contact) {
                    self.contacts = CoreDataManager.shared.getContacts()
                } else {
                    print("FAil")
                }
            }, cancelHandler: nil)
        }
    }
    
    @IBAction func contactAddButtonClicked(_ sender: Any) {
        guard let vc = storyboard!.instantiateViewController(withIdentifier: "ContactAddViewController") as? ContactAddViewController else {return}
        vc.setHandler { (name, num) in
            if CoreDataManager.shared.saveContact(name: name, num: num) {
                self.contacts = CoreDataManager.shared.getContacts()
            } else {
                print("Fail")
            }
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(vc, forKey: "contentViewController")
        present(alert, animated: true)
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        contactsCheckReset()
        dismiss(animated: true)
    }
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        guard !contacts.isEmpty else {
            showSingleAlert(title: nil, message: "공유할 연락처를 추가해주세요.", buttonLabel: "확인", handler: nil)
            return
        }
        isShareMode = true
    }
    
    @IBAction func shareCancelButtonClicked(_ sender: Any) {
        showDoubleAlert(title: "위치 공유 취소", message: "위치 공유를 취소하시겠습니까?", confirmHandler: { _ in
            NetworkManager.shared.postLocationSharingCancel { _ in
                self.showSingleAlert(title: nil, message: "위치 공유를 취소하였습니다.", buttonLabel: "확인", handler: { _ in
                    self.dismiss(animated: true)
                })
                self.setIsSharing(false)
                self.contacts.forEach { contact in
                    if contact.status != .none {
                        contact.status = .none
                    }
                }
                LSCManager.shared.sharedContacts = nil
                self.contactTableView.reloadData()
            } fail: { msg in
                self.showSingleAlert(title: "msg", message: "위치 공유 취소에 실패하였습니다.", buttonLabel: "확인", handler: nil)
            }
        }, cancelHandler: nil)
    }
    
    @IBAction func shareModeConfirmButtonClicked(_ sender: Any) {
        let shareContacts = contacts.filter {
            $0.checked
        }
        
        if shareContacts.isEmpty {
            self.showSingleAlert(title: nil, message: "선택된 연락처가 없습니다.", buttonLabel: "확인", handler: nil)
        } else {
            self.showDoubleAlert(title: "위치 공유", message: "선택된 \(shareContacts.count)개의 연락처에 위치를 공유하시겠습니까?", confirmHandler: { _ in
                self.shareMsg(shareContacts)
            }, cancelHandler: nil)
        }
    }
    
    @IBAction func timeExtensionBtnClicked(_ sender: Any) {
        if LSCManager.shared.isSharing {
            guard let sharedContacts = LSCManager.shared.sharedContacts else { return }
            showDoubleAlert(title: "공유 시간 연장", message: "전체 공유 인원의 공유 시간을 연장하시겠습니까?", confirmHandler: { _ in
                self.timeExtend(sharedContacts: sharedContacts)
            }, cancelHandler: nil)
        }
    }
    
    @IBAction func shareModeCancelButtonClicked(_ sender: Any) {
        isShareMode = false
    }
}

extension ContactViewController {
    func checkContactState() {
        if !LSCManager.shared.isSharing {
            contacts.forEach { contact in
                contact.status = .none
            }
        } else {
            guard let shareds = LSCManager.shared.sharedContacts else {return}
            contacts.forEach { contact in
                contact.status = .none
                shareds.forEach { commonContact in
                    if contact.num == commonContact.phoneNum {
                        contact.status = commonContact.status
                    }
                }
            }
        }
    }
    
    func checkShareContact() {
        guard let sharedContacts = LSCManager.shared.sharedContacts else {
            timeExtensionView.hide()
            return
        }
        if sharedContacts.count > 0 {
            timeExtensionView.show()
        } else {
            timeExtensionView.hide()
        }
        
    }
    func setBtnRound() {
        shareLocationBtn.setDefaultRound()
        shareCancelButton.setDefaultRound()
        shareCancelBtn.setDefaultRound()
        shareStartBtn.setDefaultRound()
        timeExtensionBtn.setDefaultRound()
    }
    
    func setIsSharing(_ isSharing: Bool) {
        LSCManager.shared.isSharing = isSharing
        shareCancelButton.isEnabled = isSharing
    }
    
    func contactsCheckReset() {
        contacts.forEach { contact in
            contact.checked = false
        }
    }
    
    func shareMsg(_ contacts: [Contact]) {
        NetworkManager.shared.msg = "공유시작 연락처 전송"
        guard let vc = storyboard!.instantiateViewController(withIdentifier: "ContactMessageViewController") as? ContactMessageViewController else {return}
        vc.setHandler { msg in
            self.updateShareContact(contacts, msg: msg) { response in
                print("contact")
                // 공유 성공
                guard let locSharingList = response.locSharingList else {return}
                
                if LSCManager.shared.sharedContacts == nil {
                    LSCManager.shared.sharedContacts = [CommonContact]()
                }
                
                self.contacts.forEach { contact in
                    if locSharingList.contains(where: { locSharing -> Bool in
                        locSharing.phoneNum.korTypeToPhoneNum() == contact.num
                    }) {
                        contact.status = .ready
                        let sharedContact = CommonContact()
                        sharedContact.phoneNum = contact.num
                        sharedContact.status = contact.status
                        LSCManager.shared.sharedContacts!.append(sharedContact)
                    }
                }
                
                self.showSingleAlert(title: "위치 공유", message: "위치 공유에 성공하였습니다.", buttonLabel: "확인", handler: nil)
                self.isShareMode = false
            } fail: { msg in // 연락처 단계에서 공유 실패
                self.showSingleAlert(title: msg, message: "위치 공유에 실패하였습니다.", buttonLabel: "확인", handler: nil)
                self.isShareMode = false
            }
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(vc, forKey: "contentViewController")
        present(alert, animated: true)
    }
    
    func updateShareContact(_ contacts: [Contact], msg: String, success: @escaping SuccessResult<LsListResponse>, fail: @escaping ErrorResult) {
        if LSCManager.shared.isSharing {
            self.recipientListUpdate(contacts, msg: msg, success: success, fail: fail)
        }
    }
    
    func cancelShareContact(_ contact: Contact) {
        NetworkManager.shared.msg = "공유취소 연락처 전송"
        if LSCManager.shared.isSharing {
            self.recipientListUpdate([contact], msg: "") { response in
                // 해당 연락처 제거
                LSCManager.shared.sharedContacts!.removeAll { commonContact -> Bool in
                    return commonContact.phoneNum == contact.num
                }
                self.checkContactState()
                
                guard let locSharingList = response.locSharingList else {
                    self.showSingleAlert(title: "위치 공유 취소", message: "위치 공유 취소에 실패하였습니다.", buttonLabel: "확인", handler: nil)
                    self.isShareMode = false
                    return
                }
                guard let cancelContact = locSharingList.first else {
                    self.showSingleAlert(title: "위치 공유 취소", message: "위치 공유 취소에 실패하였습니다.", buttonLabel: "확인", handler: nil)
                    self.isShareMode = false
                    return
                }
                // 해당 연락처 제거 // 추후 이 부분이 정상 로직임
//                LSCManager.shared.sharedContacts!.removeAll { commonContact -> Bool in
//                    return commonContact.phoneNum == cancelContact.phoneNum
//                }
//                self.checkContactState()
                
                self.showSingleAlert(title: "위치 공유 취소", message: "위치 공유를 취소하였습니다.", buttonLabel: "확인", handler: nil)
                self.isShareMode = false
            } fail: { msg in // 연락처 단계에서 공유 실패
                self.showSingleAlert(title: msg, message: "위치 공유 취소에 실패하였습니다.", buttonLabel: "확인", handler: nil)
                self.isShareMode = false
            }

        }
    }
    
    
    // 서버에 수신자 연락처 전송
    func recipientListUpdate(_ contacts: [Contact], msg: String, success: @escaping SuccessResult<LsListResponse>, fail: @escaping ErrorResult) {
        var list = [LocSharing]()
        contacts.forEach { contact in
            let lsStatus: Int
            if contact.status == .none {
                lsStatus = 1
            } else {
                lsStatus = 0
            }
            list.append(LocSharing(phoneNum: contact.num!.phoneNumToKorType(), profileName: contact.name!, sharerType: 1, remainTime: nil, lsStatus: lsStatus, message: msg)) // 메세지 입력받은거 전달
        }
        NetworkManager.shared.postLocationSharingRecipientListUpdate(LsListRequest(locSharingList: list), success: success, fail: fail)
    }
    
    // 공유시간 연장
    func timeExtend(sharedContacts: [CommonContact]) {
        var phoneNumList = [String]()
        
        sharedContacts.forEach { sharedContact in
            phoneNumList.append(sharedContact.phoneNum.phoneNumToKorType())
        }
        
        let timeExtendList = LocationSharingExtendRequest(phoneNum: phoneNumList, timeLeft: EXTEND_TIME)
        NetworkManager.shared.postLocationSharingTimeExtend(timeExtendList) { response in
            self.showSingleAlert(title: "공유 시간 연장", message: "공유 시간 \(response.value)분 연장에 성공하였습니다.", buttonLabel: "확인", handler: nil)
        } fail: { _ in
            self.showSingleAlert(title: "공유 시간 연장", message: "공유 시간 연장에 실패하였습니다.", buttonLabel: "확인", handler: nil)
        }
    }
}

extension ContactViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contacts[indexPath.row]
        if self.isShareMode {
            guard contact.status != .sharing else {return}
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as? ContactCell else {return}
            contact.checked = !contact.checked
            cell.setChecked(contact.checked)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
}

extension ContactViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as? ContactCell else {
            return UITableViewCell()
        }
        cell.setContact(contact: contacts[indexPath.row], index: indexPath.row)
        cell.setMode(isShareMode)
        cell.setHandler { (contact, method) in
            switch method {
            case .share:
                let message = "\(String(describing: contact.name!))님에게 위치를 공유하시겠습니끼?"
                self.showDoubleAlert(title: "위치 공유", message: message, confirmHandler: { _ in
                    self.shareMsg([contact])
                }, cancelHandler: nil)
            case .timeExtent:
                self.showDoubleAlert(title: "공유 시간 연장", message: "\(String(describing: contact.name!))님의 공유 시간을 연장하시겠습니까?", confirmHandler: { _ in
                    let commonContact = CommonContact()
                    commonContact.phoneNum = contact.num
                    self.timeExtend(sharedContacts: [commonContact])
                }, cancelHandler: nil)
            case .shareCancel:
                let message = "\(String(describing: contact.name!))님에게 위치 공유를 취소하시겠습니끼?"
                self.showDoubleAlert(title: "위치 공유 취소", message: message, confirmHandler: { _ in
                    self.cancelShareContact(contact)
                }, cancelHandler: nil)
            }
        }
        return cell
    }
}
