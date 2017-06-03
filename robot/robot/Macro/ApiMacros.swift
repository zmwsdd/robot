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

/// YY天气的key  http://api.yytianqi.com/接口名称?city=城市ID&key=用户key
/// 城市列表json格式获取地址：http://api.yytianqi.com/citylist/id/1
/*
    {"city_id":"CH","name":"中国","en":"China","list":[
        {"city_id":"CH01","name":"北京","en":"","list":[
        {"city_id":"CH010100","name":"北京","en":"Beijing"}
        ]},
        {"city_id":"CH02","name":"上海","en":"","list":[
        {"city_id":"CH020100","name":"上海","en":"Shanghai"}
        ]},
        */
let kYYWeatherKey           =   "rw6329j8m8jblmk8"
/// YY天气-7天的天气预报
let kYYWeather_url          =   "http://api.yytianqi.com/forecast7d?city=%@&key=rw6329j8m8jblmk8"
