//
//  LogCell.swift
//  Sherpa
//
//  Created by 전현성 on 2021/03/22.
//

import UIKit

class LogCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    let logs = NetworkManager.shared.logs
    
    func setLog(log: Log) {
        timeLabel.text = log.time
        nameLabel.text = log.name
        codeLabel.text = "\(log.code)"
        msgLabel.text = log.msg
    }

}
