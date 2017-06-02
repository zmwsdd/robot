//
//  SwiftBaseModel.swift
//  niaoyutong
//
//  Created by zhangmingwei on 2017/5/18.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit
import ObjectMapper

// 这里只是个例子，具体的model，还要继承Mappable
class SwiftBaseModel: Mappable {

    // 必须实现下面两个协议
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        
    }
    
}
