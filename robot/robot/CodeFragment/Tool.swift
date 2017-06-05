//
//  Tool.swift
//  niaoyutong
//
//  Created by zhangmingwei on 2017/5/27.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import AVFoundation
import MediaPlayer
import MediaToolbox

/// 网络返回的成功码
let kSuccessCode = 200
/// 当前语言是中文
let kLanguage_is_chinese = NSLocale.preferredLanguages[0].hasPrefix("zh")

//MARK:公共方法
/// 自定义Log
///
/// - Parameters:
///   - messsage: 正常输出内容
///   - file: 文件名
///   - funcName: 方法名
///   - lineNum: 行数
func SLog<T>(_ messsage: T, time: NSDate = NSDate(), file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    //    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("\(time):\(fileName):(\(lineNum))======>>>>>>\n\(messsage)")
    //    #endif
}

/// MD5加密
///
/// - Parameter str: 需要加密的字符串
/// - Returns: 32位大写加密
func md5(_ str: String) -> String {
    let cStr = str.cString(using: String.Encoding.utf8)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
    let md5String = NSMutableString()
    for i in 0 ..< 16 {
        md5String.appendFormat("%02x", buffer[i])
    }
    free(buffer)
    return md5String as String
}

/// 获取带 image/title 的按钮 (左右排列) 排序方式
public enum ButtonImageTitleType: Int {
    case imageLeft_wholeCenter   = 0       // 图片居左，整体居中
    case imageLeft_wholeLeft     = 1      // 图片居左，整体居左
    case imageleft_wholeRight    = 2      // 图片居左，整体居右
    case imageRight_wholeCenter  = 3     // 图片居右，整体居中
    case imageRight_wholeLeft    = 4    // 图片居右，整体居左
    case imageRight_wholeRight   = 5     // 图片居右，整体居右
}

public enum GradientType: Int {
    case topToBottom  = 0 //从上到小
    case leftToRight  = 1 //从左到右
    case upleftTolowRight = 2 //左上到右下
    case uprightTolowLeft  = 3//右上到左下
}



public class Tool: NSObject {
    
    static let shared = Tool()
    /**
     封装的UILabel 初始化
     
     - parameter frame:      大小位置
     - parameter textString: 文字
     - parameter font:       字体
     - parameter textColor:  字体颜色
     
     - returns: UILabel
     */
    public class func initALabel(frame:CGRect,textString:String,font:UIFont,textColor:UIColor) -> UILabel {
        let aLabel = UILabel()
        aLabel.frame = frame
        aLabel.backgroundColor = UIColor.clear
        aLabel.text = textString
        aLabel.font = font
        aLabel.textColor = textColor
        //        aLabel.sizeToFit()
        
        return aLabel
    }
    
    public class func initAImageV(frame:CGRect) -> UIImageView {
        let aImageV = UIImageView(frame: frame)
        
        return aImageV
    }
    
    public class func initATextField(frame:CGRect,textString:String,font:UIFont,textColor:UIColor) -> UITextField {
        let textF = UITextField()
        textF.frame = frame
        textF.backgroundColor = UIColor.clear
        textF.textColor = textColor
        textF.font = font
        return textF
    }
    
    /**
     封装的UIButton 初始化
     
     - parameter frame:       位置大小
     - parameter titleString: 按钮标题
     - parameter font:        字体
     - parameter textColor:   标题颜色
     - parameter bgImage:     按钮背景图片
     
     - returns: UIButton
     */
    public class func initAButton(frame:CGRect ,titleString:String, font:UIFont, textColor:UIColor, bgImage:UIImage?) -> UIButton {
        let aButton = UIButton()
        aButton.frame = frame
        aButton.backgroundColor = UIColor.clear
        aButton .setTitle(titleString, for: UIControlState.normal)
        aButton .setTitleColor(textColor, for: UIControlState.normal)
        aButton.titleLabel?.font = font
        if bgImage != nil { // bgImage 必须是可选类型，否则警告
            aButton .setBackgroundImage(bgImage, for: UIControlState.normal)
        }
        
        return aButton
    }
    
    /// 获取图片和title左右布局的按钮
    public class func initAButtonTitleImage(image:UIImage? ,title:String?, font:UIFont?, textColor:UIColor?, spacing: CGFloat, alignmentType: ButtonImageTitleType) -> UIButton {
        let aButton = UIButton()
        aButton.backgroundColor = UIColor.clear
        if let title = title {
            aButton .setTitle(title, for: UIControlState.normal)
        }
        if let textColor = textColor {
            aButton .setTitleColor(textColor, for: UIControlState.normal)
        }
        if let font = font {
            aButton.titleLabel?.font = font
        }
        aButton.titleLabel?.backgroundColor = aButton.backgroundColor
        aButton.imageView?.backgroundColor = aButton.backgroundColor
        aButton.titleLabel?.font = font
        
        if let image = image {
            aButton.setImage(image, for: .normal)
            let imageWidth:CGFloat = image.size.width
            var titleWidth:CGFloat = 0.0
            if let font = font {
                titleWidth = (aButton.currentTitle?.sizeFor(size: CGSize.init(width: SCREEN_WIDTH, height: 20), font: font).width)!
            }
            if alignmentType == .imageLeft_wholeCenter { // 图片左，整体居中
                aButton.contentHorizontalAlignment = .center
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: CGFloat(-spacing/2.0), bottom: 0, right: 0)
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: CGFloat(spacing), bottom: 0, right: 0)
            } else if alignmentType == .imageLeft_wholeLeft { // 图片左，整体居左边
                aButton.contentHorizontalAlignment = .left
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: CGFloat(spacing), bottom: 0, right: 0)
            } else if alignmentType == .imageleft_wholeRight { // 图片左，整体居右
                aButton.contentHorizontalAlignment = .right
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: CGFloat(spacing))
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            } else if alignmentType == .imageRight_wholeCenter { // 图片you，整体居中
                aButton.contentHorizontalAlignment = .center
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: CGFloat(titleWidth + spacing), bottom: 0, right: -(titleWidth + spacing))
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: CGFloat(-(imageWidth + spacing)), bottom: 0, right: imageWidth + spacing)
            } else if alignmentType == .imageRight_wholeLeft { // 图片you，整体居zuo
                aButton.contentHorizontalAlignment = .left
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: titleWidth + spacing, bottom: 0, right: -(titleWidth + spacing))
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: -(imageWidth + spacing), bottom: 0, right: imageWidth + spacing)
            } else if alignmentType == .imageRight_wholeRight { // 图片you，整体居中
                aButton.contentHorizontalAlignment = .right
                aButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: titleWidth + spacing, bottom: 0, right: -(titleWidth + spacing))
                aButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: -(imageWidth + spacing), bottom: 0, right: imageWidth + spacing)
            }
        }
        
        return aButton
    }
    
    /// 保存NSArray 数据到本地文件
    public class func saveArrayToFile(resultArray: NSArray! , fileName: String!) {
        let jsonString : NSString = self.toJSONString(arr: resultArray)!
        let jsonData :Data? = jsonString.data(using: UInt(String.Encoding.utf8.hashValue))
        
        let file = fileName
        let fileUrl = URL(fileURLWithPath: kPathTemp).appendingPathComponent(file!)
        print("fileUrl = \(fileUrl)")
        let data = NSMutableData()
        data.setData(jsonData!)
        if data.write(toFile: fileUrl.path, atomically: true) {
            print("保存成功：\(fileUrl.path)")
        } else {
            print("保存失败：\(fileUrl.path)")
        }
    }
    
    /// 从本地获取json数据
    public class func getJsonFromFile(fileName: String) -> Any? {
        let file = fileName
        let fileUrl = URL(fileURLWithPath: kPathTemp).appendingPathComponent(file)
        if let readData = NSData.init(contentsOfFile: fileUrl.path) {
            let jsonValue = try? JSONSerialization.jsonObject(with: readData as Data, options: .allowFragments)
            print("获取成功：\(fileUrl.path)")
            return jsonValue
        } else {
            print("获取失败：\(fileUrl.path)")
            return nil
        }
    }
    
    /// 转换数组到JSONStirng
    public class func toJSONString(arr: NSArray!) -> NSString? {
        guard let data = try? JSONSerialization.data(withJSONObject: arr, options: .prettyPrinted),
            // Notice the extra question mark here!
            let strJson = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                //throws MyError.InvalidJSON
                return nil
        }
        return strJson
    }
    
    // MARK: 网络相关的类方法
    public class func getCode(result: JSON?) -> Int? {
        let code = result?["code"].int
        return code
    }
    public class func getMessage(result: JSON?) -> String? {
        let message = result?["message"].string
        return message
    }
    
    /// MARK: - 判断一个方法调用频繁的方法 - 两个方法交替调用不会被打断
    public class func isCallFrequent(funcName: String) -> Bool {
        struct Frequent {
            static var isFrequentFlag: Bool = false // 默认没有频繁调用
            static var lastFuncName : String = "defaultFuncName" // 默认的方法名字
        }
        if Frequent.lastFuncName != funcName { // 和上次的方法名字不一样就认为是不同的方法
            Frequent.isFrequentFlag = false
            Frequent.lastFuncName = funcName
        }
        if Frequent.isFrequentFlag { // 频繁调用了
            print("频繁被调用了--还没超过0.5秒")
            return true
        } else {  // 没有频繁调用
            /// 延迟0.5秒后执行
            Frequent.isFrequentFlag = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                Frequent.isFrequentFlag = false
            }
            return false
        }
    }
    
    /// 类文件字符串转换为ViewController
    ///
    /// - Parameter childControllerName: VC的字符串
    /// - Returns: ViewController
    public class func vcString_to_ViewController(_ childControllerName: String) -> UIViewController?{
        
        // 1.获取命名空间
        // 通过字典的键来取值,如果键名不存在,那么取出来的值有可能就为没值.所以通过字典取出的值的类型为AnyObject?
        guard let clsName = Bundle.main.infoDictionary!["CFBundleExecutable"] else {
            print("命名空间不存在")
            return nil
        }
        // 2.通过命名空间和类名转换成类
        let cls : AnyClass? = NSClassFromString((clsName as! String) + "." + childControllerName)
        
        // swift 中通过Class创建一个对象,必须告诉系统Class的类型
        guard let clsType = cls as? UIViewController.Type else {
            print("无法转换成UIViewController")
            return nil
        }
        // 3.通过Class创建对象
        let childController = clsType.init()
        
        return childController
    }
    
    /// 播放震动
    public class func playVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

   /// 停止震动
    public class func stopVibration() {
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
    }
    /// 设置声音变小 - 录音的时候需要小
    public class func volumeLittle() {
        let session = AVAudioSession.sharedInstance()
        if session.category != AVAudioSessionCategoryPlayAndRecord {
            try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try! session.setActive(true)
        }
    }
   /// 设置声音变大 - 播放声音的时候需要大
    public class func volumeBig() {
        let session = AVAudioSession.sharedInstance()
        if session.category != AVAudioSessionCategoryPlayback {
            try! session.setCategory(AVAudioSessionCategoryPlayback)
            try! session.setActive(true)
        }
    }
    
    /// 改变系统声音为最大
    public class func changeVolumeToMax() {
        let volumeBig = MPVolumeView()
        var slider: UISlider?
        for view: UIView in volumeBig.subviews {
        SLog(view.self.description)
            SLog(view.className())
            if view.className() == "MPVolumeSlider" {
                slider = view as? UISlider
                break
            }
        }
        let systemVolume = slider?.value ?? 0.5
        if systemVolume < 0.9 {
            slider?.setValue(0.9, animated: false)
            slider?.sendActions(for: .touchUpInside)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
