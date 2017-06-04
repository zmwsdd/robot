//
//  HomeVC.swift
//  robot
//
//  Created by zhangmingwei on 2017/6/2.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit
import Speech

class HomeVC: SwifBaseViewController,SFSpeechRecognitionTaskDelegate {
    /// ios自带的语音识别引擎
    var bufferRec: SFSpeechRecognizer!
    var bufferTask: SFSpeechRecognitionTask?
    var bufferRequest: SFSpeechAudioBufferRecognitionRequest!
    var bufferEngine: AVAudioEngine!
    var bufferInputNode: AVAudioInputNode!
    var myTimer: Timer?
    
    /// 识别到的结果字符串
    var resultStr: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        // 开始识别
        self.beginListening()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 停止识别
        self.stopListening()
    }
    
    // 停止识别
    func stopListening() {
        SLog("停止识别")
        ProgressHUD.dismissDelay(0)
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
        SLog("开始识别。。。")
        ProgressHUD.showCustomLoadListening(self.view, title: "倾听中...")
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
                        ProgressHUD.dismissDelay(0)
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
            SLog("resultStr ==== \(String(describing: self.resultStr!))")
            if (self.resultStr?.contains("天气"))! {
                self.weatherAction()
            } else if self.resultStr != nil {
                self.baiduNewsAction()
            } else {
                SoundPlayer.defaltManager().play(self.resultStr, languageType: LanguageTypeChinese)
            }
        }, repeats: false)
    }
    
    // 获取天气情况的方法
    func weatherAction() {
    let url = String.init(format: kYYWeather_url,"CH010100")
        ProgressHUD.showCustomLoadListening(self.view, title: "查询中...")
        // 这里必须用get请求，因为好多第三方都不是同时支持get和post的
        _ = JHNetwork.shared.getForJSON(url: url) { [unowned self] (result, error) in
           SLog(result)
            var weatherStr = "不好意思获取天气失败"
            if let arr = result?["data"]["list"].arrayObject {
                if arr.count == 1 {
                    if let dic = arr[0] as? [String: String] {
                        weatherStr = String.init(format: "主人我已经查询成功！今天最低温度%@度，最高温度%@度，%@，%@",dic["qw2"]!,dic["qw1"]!,dic["fl2"]!,dic["fl1"]!)
                    }
                } else if arr.count == 2 {
                    if let dic = arr[0] as? [String: String] {
                        weatherStr = String.init(format: "主人我已经查询成功！今天最低温度%@度，最高温度%@度，%@，%@",dic["qw2"]!,dic["qw1"]!,dic["fl2"]!,dic["fl1"]!)
                    }
                    if (self.resultStr?.contains("明天"))! {
                        if let dic = arr[1] as? [String: String] {
                            weatherStr = String.init(format: "主人我已经查询成功！明天最低温度%@度，最高温度%@度，%@，%@",dic["qw2"]!,dic["qw1"]!,dic["fl2"]!,dic["fl1"]!)
                        }
                    }
                }
            }
            SoundPlayer.defaltManager().play(weatherStr, languageType: LanguageTypeChinese)
            ProgressHUD.dismissDelay(0)
        }
    }
    // 获取新闻查询结果的方法
    func baiduNewsAction() {
        let url = String.init(format: kBaidu_new_url,self.resultStr!).urlEncode
        ProgressHUD.showCustomLoadListening(self.view, title: "查询中...")
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
                SoundPlayer.defaltManager().play(baiduSearchResultArr[0], languageType: LanguageTypeChinese)
            }
            ProgressHUD.dismissDelay(0)
        }
    }
    
}


