//
//  ContactMessageViewController.swift
//  Sherpa
//
//  Created by 전현성 on 2021/03/12.
//

import UIKit

class ContactMessageViewController: UIViewController {

    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var frameHeight: NSLayoutConstraint!
    

    @IBOutlet weak var enterBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var handler: ((String) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: view.frame.width, height: frameHeight.constant)
        
        enterBtn.setDefaultRound()
        cancelBtn.setDefaultRound()
        messageField.delegate = self
    }

    

    @IBAction func enterBtn(_ sender: Any) {
        var resultMsg = messageField.text!
        if resultMsg.isEmpty {
            resultMsg = "공유합니다"
        }
        handler(resultMsg)
        dismiss(animated: true)
    }
    @IBAction func cancelBtn(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func setHandler(handler: @escaping (String) -> Void) {
        self.handler = handler
    }
}

extension ContactMessageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
