//
//  RouteBookmarkCell.swift
//  Sherpa
//
//  Created by 고준권 on 2021/02/26.
//

import UIKit

class RouteBookmarkCell: UITableViewCell {

    @IBOutlet weak var bookmarkName: UILabel!
    @IBOutlet weak var bookmarkAddress: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setBookmarkData(_ bookmark: Bookmark) {
        bookmarkName.text = bookmark.name
        bookmarkAddress.text = bookmark.address
    }
}
