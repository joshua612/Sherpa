//
//  ContactAddViewController.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/23.
//

import UIKit

class ContactAddViewController: UIViewController {

    @IBOutlet weak var frameHeight: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var numTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    var handler: ((String, String)->Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: view.frame.width, height: frameHeight.constant)
        
        addBtn.setDefaultRound()
        cancelBtn.setDefaultRound()
        nameTextField.delegate = self
        numTextField.delegate = self
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
        if nameTextField.text!.isEmpty {
            warningLabel.text = "이름을 입력하세요."
            return
        }
        
        if numTextField.text!.isEmpty {
            warningLabel.text = "연락처를 입력하세요."
            return
        }
        
        warningLabel.text = ""
        
        handler(nameTextField.text!, numTextField.text!)
        dismiss(animated: true)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func setHandler(handler: @escaping (String, String)-> Void) {
        self.handler = handler
    }
    
}

extension ContactAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            numTextField.becomeFirstResponder()
        } else {
            numTextField.resignFirstResponder()
        }
        return true
    }
}
