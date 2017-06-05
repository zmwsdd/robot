//
//  ApiMacros.swift
//  SwiftCodeFragments
//
//  Created by zhangmingwei on 2017/2/3.
//  Copyright © 2017年 SpeedX. All rights reserved.
//

import Foundation

// -- swift 的api以 kS开头

// 域名
let kSDomain                 =   ".niaoyutong.com"
// 请求的根url
let kSBase_url               =   ""
// 请求的key（暂时需要）
let kSRequest_key            =   ""


// 业务逻辑的具体API：
/// 阿凡达天气数据的接口
/// YY天气-7天的天气预报 + 城市名字例如：武汉
let kYYWeather_url          =   "http://api.avatardata.cn/Weather/Query?key=f06098f5db9f43fbbfe04aba61bb94fb&cityname=%@"

/// 百度新闻搜索json数据
let kBaidu_new_url          =   "http://www.baidu.com/s?wd=%@&pn=0&rn=3&tn=json"
