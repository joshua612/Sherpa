//
//  TableViewCell.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/23.
//

import UIKit

enum ContactCellMethodType {
    case share
    case timeExtent
    case shareCancel
}

class ContactCell: UITableViewCell {
    typealias ContactCellMethod = ((Contact, ContactCellMethodType)-> Void)

    @IBOutlet weak var cellCase: UIView!
    @IBOutlet weak var checkboxCase: UIView!
    @IBOutlet weak var buttonCase: UIView!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numLabel: UILabel!
    @IBOutlet weak var stateView: UIView!
    
    @IBOutlet weak var shareButton: RoudedButton!
    @IBOutlet weak var timeExtendButton: RoudedButton!
    @IBOutlet weak var shareCancelButton: RoudedButton!
    
    var handler: ContactCellMethod!
    var contact: Contact! {
        didSet {
            nameLabel.text = contact.name
            numLabel.text = contact.num
            setStatus(contact.status)
            if contact.status != .none {
                setDischeckable()
            } else {
                setChecked(contact.checked)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellCase.setTopbarShadow()
        cellCase.layer.cornerRadius = 10
        stateView.setCircleView()
    }
    
    func setContact(contact: Contact, index: Int) {
        self.contact = contact
    }
    
    func setChecked(_ isChecked: Bool) {
        let imageName = isChecked ? "checkmark.square.fill" : "square"
        checkImageView.image = UIImage(systemName: imageName)
        checkImageView.tintColor = .white
    }
    
    func setDischeckable() {
        checkImageView.image = UIImage(systemName: "xmark.square.fill")
        checkImageView.tintColor = .gray
    }
    
    func setMode(_ isShareMode: Bool) {
        checkboxCase.isHidden = !isShareMode
        buttonCase.isHidden = isShareMode
    }
    
    func setHandler(_ handler: @escaping ContactCellMethod) {
        self.handler = handler
    }
    
    func setStatus(_ status: SharingStatus) {
        switch status {
        case .none:
            stateView.backgroundColor = .clear
            shareButton.show()
            timeExtendButton.hide()
            shareCancelButton.hide()
        case .ready:
            stateView.backgroundColor = .orange
            shareButton.hide()
            timeExtendButton.show()
            shareCancelButton.show()
        case .sharing:
            stateView.backgroundColor = .green
            shareButton.hide()
            timeExtendButton.show()
            shareCancelButton.show()
        }
    }

    @IBAction func shareButtonClicked(_ sender: Any) {
        handler(contact, .share)
    }
    
    @IBAction func timeExtendButtonClicked(_ sender: Any) {
        handler(contact, .timeExtent)
    }
    
    @IBAction func shareCancelButtonClicked(_ sender: Any) {
        handler(contact, .shareCancel)
    }
}
