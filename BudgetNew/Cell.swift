//
//  Cell.swift
//  BudgetNew
//
//  Created by linoj ravindran on 06/03/2019.
//  Copyright © 2019 linoj ravindran. All rights reserved.
//

import Foundation
import UIKit
class Cell: UITableViewCell {
    
    @IBOutlet var title: UILabel!
    @IBOutlet var amount: UILabel!
    @IBOutlet var last: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
}

