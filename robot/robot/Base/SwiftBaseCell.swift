//
//  SwiftBaseCell.swift
//  niaoyutong
//
//  Created by zhangmingwei on 2017/5/18.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit
import Cartography

class SwiftBaseCell: UITableViewCell {

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let selectBgView = UIView.init(frame: self.frame);
        selectBgView.backgroundColor = UIColor.colorRGB16(value: 0xececec)
        
        self.selectedBackgroundView = selectBgView;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
