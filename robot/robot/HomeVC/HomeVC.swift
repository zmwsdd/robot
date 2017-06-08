//
//  HomeVC.swift
//  robot
//
//  Created by zhangmingwei on 2017/6/2.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit
import Speech

class HomeVC: SwifBaseViewController,SFSpeechRecognitionTaskDelegate,CLLocationManagerDelegate,UITextViewDelegate {
    /// ios自带的语音识别引擎
    var bufferRec: SFSpeechRecognizer!
    var bufferTask: SFSpeechRecognitionTask?
    var bufferRequest: SFSpeechAudioBufferRecognitionRequest!
    var bufferEngine: AVAudioEngine!
    var bufferInputNode: AVAudioInputNode!
    var myTimer: Timer?
    
    /// 识别到的结果字符串
    var resultStr: String?
    
    var askTitleV: UITextView!
    var textV: UITextView!
    
    /// 获取当然位置
    var locationManager : CLLocationManager!
    var currLocation : CLLocation!
    var currentCity: String! = "北京市"
    
    var canStarSpeechFlag: Bool = true // 当离开当前页面或者正在播放语音的时候都是NO
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canStarSpeechFlag = true
        self.addTitle(titleString: NSLocalizedString("机器人", comment: ""))
        
        self.initLocation()
        // 初始化view
        self.initAllView()
        
        // 初始化语音识别方法
        self.initSpeechAction()
        
        // 停止播放声音后-开始识别
        NotificationCenter.default.rac_addObserver(forName: kNotificationSoudDidStop, object: nil).subscribeNext { [unowned self] (notifi) in
                self.beginListening()
        }
        // 进入前台的时候
        NotificationCenter.default.rac_addObserver(forName: kNotificationWillBecomeFront, object: nil).subscribeNext { [unowned self] (notifi) in
            self.beginListening()
        }
        // 进入后台的通知
        NotificationCenter.default.rac_addObserver(forName: kNotificationWillEnterBg, object: nil).subscribeNext { [unowned self] (notifi) in
            self.stopListening()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        canStarSpeechFlag = true
        // 开始识别
        self.beginListening()
        self.navigationItem.rightBarButtonItems = nil
        self.rightButton(name: "网页搜索", image: nil) { [unowned self] (btn) in
            let vc = WKWebViewVC()
            var str = self.askTitleV.text
            if String.isEmptyString(str: self.askTitleV.text) {
                str = self.resultStr ?? ""
            }
            vc.hidesBottomBarWhenPushed = true
//            vc.urlStr = String.init(format: "https://www.baidu.com/s?wd=%@",str!).urlEncode  /// 二级页面不能重新加载（拿不到回调）
            vc.urlStr = String.init(format: "https://www.sogou.com/web?query=%@",str!).urlEncode

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        canStarSpeechFlag = false
        // 停止识别
        self.stopListening()
    }
    
    /// 初始化位置信息
    func initLocation() {
        if let currentC = UserDefaults.standard.value(forKey: "currentCity") as? String {
            self.currentCity = currentC
        }
        //初始化位置管理器
        locationManager = CLLocationManager()
        locationManager.delegate = self
        //设备使用电池供电时最高的精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //精确到1000米,距离过滤器，定义了设备移动后获得位置信息的最小距离
        locationManager.distanceFilter = kCLLocationAccuracyKilometer
        //如果是IOS8及以上版本需调用这个方法
        locationManager.requestAlwaysAuthorization()
        //使用应用程序期间允许访问位置数据
        locationManager.requestWhenInUseAuthorization();
        //启动定位
        locationManager.startUpdatingLocation()
    }
    
    //FIXME: CoreLocationManagerDelegate 中获取到位置信息的处理函数
    func  locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations[locations.count-1] as CLLocation
        currLocation=location
        if (location.horizontalAccuracy > 0) {
            self.locationManager.stopUpdatingLocation()
            print("wgs84坐标系  纬度: \(location.coordinate.latitude) 经度: \(location.coordinate.longitude)")
            self.locationManager.stopUpdatingLocation()
            print("结束定位")
        }
        //使用坐标，获取地址
        let geocoder = CLGeocoder()
        var p:CLPlacemark?
        geocoder.reverseGeocodeLocation(currLocation, completionHandler: { [unowned self] (placemarks, error) -> Void in
            if error != nil {
                print("获取地址失败: \(error!.localizedDescription)")
                return
            }
            let pm = placemarks! as [CLPlacemark]
            if (pm.count > 0){
                p = placemarks![0] as CLPlacemark
                print("地址:\(String(describing: p?.locality!))")
                if let city = p?.locality {
                    self.currentCity = city // 北京市
                    if !String.isEmptyString(str: self.currentCity) {
                        UserDefaults.standard.setValue(self.currentCity, forKey: "currentCity")
                        UserDefaults.standard.synchronize()
                    }
                }
            }else{
                print("没地址!")
            }
        })
    }
    //FIXME:  获取位置信息失败
    func  locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func initAllView() {
        askTitleV = UITextView.init(frame: CGRect.init(x: 0, y: NAVIGATIONBAR_HEIGHT, width: SCREEN_WIDTH, height: 80))
        view.addSubview(askTitleV)
        askTitleV.font = FONT_PingFang(fontSize: 17)
        askTitleV.textColor = UIColor.getMainColorSwift()
        askTitleV.textAlignment = .center
        askTitleV.delegate = self
        
        self.textV = UITextView.init(frame: CGRect.init(x: 0, y: NAVIGATIONBAR_HEIGHT + 100, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - NAVIGATIONBAR_HEIGHT - 100))
        self.view.addSubview(self.textV)
        textV.font = FONT_PingFang(fontSize: 17)
        textV.textColor = UIColor.getMainColorSwift()
        textV.isUserInteractionEnabled = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.resultStr = textView.text ?? ""
        if String.isEmptyString(str: resultStr) {
            return
        }
        self.stopListening()
        if (self.resultStr?.contains("天气"))! {
            SoundPlayer.defaltManager().stopAction()
            self.weatherAction()
        } else if (self.resultStr?.contains("重读"))! || (self.resultStr?.contains("重复"))! || (self.resultStr?.contains("再读"))!{
            SoundPlayer.defaltManager().stopAction()
            self.canStarSpeechFlag = false
            SoundPlayer.defaltManager().play(self.textV.text, languageType: LanguageTypeChinese)
        } else if (self.resultStr?.contains("退下"))! || (self.resultStr?.contains("结束吧"))! || (self.resultStr?.contains("退出"))!{
            Tool.exitApplication() // 退出APP
        } else if self.resultStr != nil {
            SoundPlayer.defaltManager().stopAction()
            self.sougouSearchAction()
        } else {
            self.canStarSpeechFlag = false
            SoundPlayer.defaltManager().stopAction()
            SoundPlayer.defaltManager().play(self.resultStr, languageType: LanguageTypeChinese)
        }
    }
    
    // 停止识别
    func stopListening() {
        SLog("停止识别")
        askTitleV.resignFirstResponder()
        canStarSpeechFlag = false
        SoundPlayer.defaltManager().stopAction()
        self.addTitle(titleString: "机器人")
        self.bufferEngine.stop()
        self.bufferInputNode.removeTap(onBus: 0)
        self.bufferTask = nil
    }

    // 初始化语音识别方法
    func initSpeechAction() {
        /// 初始化语音识别相关的引擎 - 只需要初始化一次的
        bufferEngine = AVAudioEngine()
        bufferRec = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh_CN"))
        bufferInputNode = bufferEngine.inputNode
        bufferRequest = SFSpeechAudioBufferRecognitionRequest()
        bufferRequest.shouldReportPartialResults = true
    }
    
    // 开始识别
    func beginListening() {
        canStarSpeechFlag = true
        SoundPlayer.defaltManager().stopAction()
        if Tool.isCallFrequent(funcName: "beginListening") {
            SLog("开始识别。。。")
            return;
        }
        self.addTitle(titleString: "倾听中...")
        Tool.volumeLittle()
        // 麦克风权限检查和开启
        let avSession = AVAudioSession.sharedInstance()
            avSession.requestRecordPermission({ (available) in
                if available {
                    DispatchQueue.main.async {
                        // 申请用户语音识别权限
                        SFSpeechRecognizer.requestAuthorization({ [unowned self] (status) in
                            if status != SFSpeechRecognizerAuthorizationStatus.authorized {
                                // 停止监听
                               let alertVC = UIAlertController.initAlertC(title: "请进入设置->隐私->语音识别->开启授权", msg: nil, style: .alert)
                               alertVC.addMyAction(title: "确定", style: .default)
                               alertVC.showAlertC(vc: self, completion: nil)
                            } else {
                                // 已经授权了
                                if (self.bufferEngine != nil) {
                                    self.bufferEngine.stop()
                                    self.bufferInputNode.removeTap(onBus: 0)
                                    self.bufferInputNode.reset()
                                }
                                self.bufferTask = nil
                                self.beginSpeechAction()
                            }
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        let alertVC = UIAlertController.initAlertC(title: "请进入设置->隐私->麦克风->开启授权", msg: nil, style: .alert)
                        alertVC.addMyAction(title: "确定", style: .default)
                        alertVC.showAlertC(vc: self, completion: nil)
                        self.addTitle(titleString: "机器人")
                    }
                }
            })
     }
    
     // 真正的开始识别的方法
    func beginSpeechAction() {
        self.bufferRequest = nil;
        self.bufferRequest = SFSpeechAudioBufferRecognitionRequest()
        self.bufferRequest.shouldReportPartialResults = true;
        self.bufferRec = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh_CN"))
        self.bufferTask = self.bufferRec.recognitionTask(with: self.bufferRequest, delegate: self)
        // 监听一个标识位并拼接流文件
        let format = self.bufferInputNode.outputFormat(forBus: 0)
        self.bufferInputNode .installTap(onBus: 0, bufferSize: 1024, format: format) { [unowned self] (buffer, when) in
            self.bufferRequest.append(buffer)
        }
        // 准备启动引擎
        self.bufferEngine.prepare()
        try! self.bufferEngine.start()

    }
    // 识别到结果的方法，这个方法会不断的执行。
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        self.myTimer?.invalidate()
        self.myTimer = nil
        self.myTimer = Timer.scheduledTimer(withTimeInterval: 1.0, block: { [unowned self] (timer) in
            self.resultStr = transcription.formattedString
            SLog(self.resultStr)
            SLog("resultStr ==== \(String(describing: self.resultStr!))")
            if (self.resultStr?.contains("天气"))! {
                self.weatherAction()
            } else if (self.resultStr?.contains("重读"))! || (self.resultStr?.contains("重复"))! || (self.resultStr?.contains("再读"))!{
                self.canStarSpeechFlag = false
                SoundPlayer.defaltManager().play(self.textV.text, languageType: LanguageTypeChinese)
                
            } else if (self.resultStr?.contains("退下"))! || (self.resultStr?.contains("结束吧"))! || (self.resultStr?.contains("退出"))!{
                Tool.exitApplication() // 退出APP
            } else if self.resultStr != nil {
                self.sougouSearchAction()
            } else {
                self.canStarSpeechFlag = false
                SoundPlayer.defaltManager().play(self.resultStr, languageType: LanguageTypeChinese)
            }
        }, repeats: false)
    }
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        if self.canStarSpeechFlag {
            SLog("长时间不说话，重启识别")
            DispatchQueue.main.async {
                self.beginListening()
            }
        }
    }
    /// 长识别不说话会进入这个代理方法，以后就不能识别了。所以需要在这里开启识别
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if self.canStarSpeechFlag {
            SLog("长时间不说话，重启识别")
            DispatchQueue.main.async {
                self.beginListening()
            }
        }
    }
    
    // 获取天气情况的方法
    func weatherAction() {
    SLog("当前城市是：\(self.currentCity)")
    askTitleV.text = self.resultStr
    let url = String.init(format: kYYWeather_url,self.currentCity).urlEncode
        self.addTitle(titleString: "查询中...")
        // 这里必须用get请求，因为好多第三方都不是同时支持get和post的
        _ = JHNetwork.shared.getForJSON(url: url!) { [unowned self] (result, error) in
           SLog(result)
            var weatherStr = "不好意思获取天气失败"
            if let arr = result?["result"]["weather"].arrayObject {
                if arr.count > 1 {
                    // 温度
                    var temp0 = "0" // 默认的最低温度
                    var temp1 = "0" // 默认的最高温度
                    if let temp = result?["result"]["weather"][0]["info"]["night"][2].rawString() {
                        temp0 = temp
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["day"][2].rawString() {
                        temp1 = temp
                    }
                    let temper = String.init(format: "%@到%@度",temp0,temp1)
                    // 天气多云或者晴天
                    var rain0 = "多云" // 默认的天气
                    var rain1 = "晴"  // 默认的天气
                    if let temp = result?["result"]["weather"][0]["info"]["day"][1].rawString() {
                        rain0 = temp
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["night"][1].rawString() {
                        rain1 = temp
                    }
                    var rain = String.init(format: "%@转%@",rain0,rain1)
                    if rain0 == rain1 {
                        rain = String.init(format: "%@",rain0)
                    }
                    // 风的情况
                    var wind0 = "微风" // 默认的天气
                    var wind1 = "微风"  // 默认的天气
                    if let temp = result?["result"]["weather"][0]["info"]["day"][4].rawString() {
                        wind0 = temp
                        if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                            wind0.append("风")
                        }
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["night"][4].rawString() {
                        wind1 = temp
                        if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                            wind1.append("风")
                        }
                    }
                    var wind = String.init(format: "%@,转,%@",wind0,wind1)
                    if wind0 == wind1 {
                        wind = wind0
                    }
                    weatherStr = String.init(format: "主人我已经查询成功！今天%@，%@，%@",temper,rain,wind)
                    if (self.resultStr?.contains("明天"))! {
                        // 温度
                        var temp0 = "0" // 默认的最低温度
                        var temp1 = "0" // 默认的最高温度
                        if let temp = result?["result"]["weather"][1]["info"]["night"][2].rawString() {
                            temp0 = temp
                        }
                        if let temp = result?["result"]["weather"][1]["info"]["day"][2].rawString() {
                            temp1 = temp
                        }
                        let temper = String.init(format: "%@到%@度",temp0,temp1)
                        // 天气多云或者晴天
                        var rain0 = "多云" // 默认的天气
                        var rain1 = "晴"  // 默认的天气
                        if let temp = result?["result"]["weather"][1]["info"]["day"][1].rawString() {
                            rain0 = temp
                        }
                        if let temp = result?["result"]["weather"][1]["info"]["night"][1].rawString() {
                            rain1 = temp
                        }
                        var rain = String.init(format: "%@转%@",rain0,rain1)
                        if rain0 == rain1 {
                            rain = String.init(format: "%@",rain0)
                        }
                        // 风的情况
                        var wind0 = "微风" // 默认的天气
                        var wind1 = "微风"  // 默认的天气
                        if let temp = result?["result"]["weather"][1]["info"]["day"][4].rawString() {
                            wind0 = temp
                            if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                                wind0.append("风")
                            }
                        }
                        if let temp = result?["result"]["weather"][1]["info"]["night"][4].rawString() {
                            wind1 = temp
                            if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                                wind1.append("风")
                            }
                        }
                        var wind = String.init(format: "%@,转,%@",wind0,wind1)
                        if wind0 == wind1 {
                            wind = wind0
                        }
                        weatherStr = String.init(format: "主人我已经查询成功！明天%@，%@，%@",temper,rain,wind)
                    }
                } else if arr.count > 0 {
                    // 温度
                    var temp0 = "0" // 默认的最低温度
                    var temp1 = "0" // 默认的最高温度
                    if let temp = result?["result"]["weather"][0]["info"]["night"][2].rawString() {
                        temp0 = temp
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["day"][2].rawString() {
                        temp1 = temp
                    }
                    let temper = String.init(format: "%@到%@度",temp0,temp1)
                    // 天气多云或者晴天
                    var rain0 = "多云" // 默认的天气
                    var rain1 = "晴"  // 默认的天气
                    if let temp = result?["result"]["weather"][0]["info"]["day"][1].rawString() {
                        rain0 = temp
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["night"][1].rawString() {
                        rain1 = temp
                    }
                    var rain = String.init(format: "%@转%@",rain0,rain1)
                    if rain0 == rain1 {
                        rain = String.init(format: "%@",rain0)
                    }
                    // 风的情况
                    var wind0 = "微风" // 默认的天气
                    var wind1 = "微风"  // 默认的天气
                    if let temp = result?["result"]["weather"][0]["info"]["day"][4].rawString() {
                        wind0 = temp
                        if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                            wind0.append("风")
                        }
                    }
                    if let temp = result?["result"]["weather"][0]["info"]["night"][4].rawString() {
                        wind1 = temp
                        if (temp.contain(ofString: "级")) && !(temp.contain(ofString: "级风")) {
                            wind1.append("风")
                        }
                    }
                    var wind = String.init(format: "%@,转,%@",wind0,wind1)
                    if wind0 == wind1 {
                        wind = wind0
                    }
                    weatherStr = String.init(format: "主人我已经查询成功！今天%@，%@，%@",temper,rain,wind)
                }
            }
            self.textV.text = weatherStr
            self.canStarSpeechFlag = false
            SoundPlayer.defaltManager().play(weatherStr, languageType: LanguageTypeChinese)
            self.addTitle(titleString: "机器人")
        }
    }
    // 获取新闻查询结果的方法
    func baiduNewsAction() {
        let url = String.init(format: kBaidu_new_url,self.resultStr!).urlEncode
        self.addTitle(titleString: "查询中...")
        askTitleV.text = self.resultStr
        // 这里必须用get请求，因为好多第三方都不是同时支持get和post的
        _ = JHNetwork.shared.getForJSON(url: url!) { [unowned self] (result, error) in
            SLog(result)
            var baiduSearchResultArr: [String] = []
            if let arr = result?["feed"]["entry"].arrayObject {
                if arr.count > 0  {
                    if let dic0 = arr[0] as? [String: Any] {
                        baiduSearchResultArr.append(dic0["abs"]! as! String)
                    }
                    if arr.count > 1, let dic1 = arr[1] as? [String: Any] {
                        baiduSearchResultArr.append(dic1["abs"]! as! String)
                    }
                    if arr.count > 2, let dic2 = arr[2] as? [String: Any] {
                        baiduSearchResultArr.append(dic2["abs"]! as! String)
                    }
                }
            }
            if baiduSearchResultArr.count > 0 {
                self.textV.text = baiduSearchResultArr[0]
                self.canStarSpeechFlag = false
                SoundPlayer.defaltManager().play(baiduSearchResultArr[0], languageType: LanguageTypeChinese)
            }
            self.addTitle(titleString: "机器人")
        }
    }
    // 搜狗搜索
    func sougouSearchAction() {
        self.addTitle(titleString: "查询中...")
        let session = URLSession.shared
        let urlStr = String.init(format: "http://wenwen.sogou.com/s/?w=%@&pg=0",self.resultStr!).urlEncode
        askTitleV.text = self.resultStr
        session.dataTask(with: URL.init(string: urlStr!)!) { [unowned self] (data, urlResponse, error) in
            if let result = data {
                let totalResultStr: String! = String.init(data: result, encoding: String.Encoding.utf8) ?? "暂五数据"
                let firstStr: String = totalResultStr.getSubStr(beginStr: "<div class=\"result-summary\">", endStr: "</div><div class=\"result-info sIt_info\">")
                let secondTemp = totalResultStr.removeFirstSubString(beginStr: "<div class=\"result-summary\">", endStr: "</div><div class=\"result-info sIt_info\">")
                let secondStr = secondTemp.getSubStr(beginStr: "<div class=\"result-summary\">", endStr: "</div><div class=\"result-info sIt_info\">")
                let lastStr1 = firstStr.removeAllSubString(beginStr: "<", endStr: ">")
                let lastStr2 = secondStr.removeAllSubString(beginStr: "<", endStr: ">")
                DispatchQueue.main.async {
                    if String.isEmptyString(str: secondStr) {
                        self.textV.text = String.init(format: "%@",lastStr1)
                    } else {
                        self.textV.text = String.init(format: "答案一：%@\n\n答案二：%@",lastStr1,lastStr2)
                    }
                    self.canStarSpeechFlag = false
                    SoundPlayer.defaltManager().play(self.textV.text, languageType: LanguageTypeChinese)
                    self.addTitle(titleString: "机器人")
                }
            }
            }.resume()
    }
    
}


