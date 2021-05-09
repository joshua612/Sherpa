//
//  CustomView.swift
//  Sherpa
//
//  Created by 고준권 on 2021/03/18.
//

import Foundation
import UIKit

class CircleButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewInit()
    }
    
    func viewInit() {
        self.setCircleView()
        self.setDefaultShadow()
    }
}

class RoudedButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewInit()
    }
    
    func viewInit() {
        self.setDefaultRound()
    }
}
