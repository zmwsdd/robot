//
//  WKWebViewVC.swift
//  niaoyutong
//
//  Created by zhangmingwei on 2017/5/27.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewVC: SwifBaseViewController,WKNavigationDelegate {

    var titleStr: String? // 当前页面的标题
    var urlStr: String? // 网络的url
    public var localPathStr: String? // 本地地址
    
    var webView: WKWebView!
    var urlRequest: URLRequest?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 添加标题
        if !NSString.isEmpty(titleStr) {
            self.addTitle(titleString: titleStr!)
        }
        // 初始化webView和进度条
        self.initWebViewAndProgressV()
        // 加载网页
        self.loadUrlRequest()
    }
    
    // 加载webView和进度条
    func initWebViewAndProgressV() {
        // WKWebView自适应文字大小
        let js = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let wkUserScript = WKUserScript.init(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkController = WKUserContentController()
        wkController.addUserScript(wkUserScript)
        let wkConfig = WKWebViewConfiguration()
        wkConfig.userContentController = wkController
        webView = WKWebView.init(frame: CGRect.init(x: 0, y: NAVIGATIONBAR_HEIGHT, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - NAVIGATIONBAR_HEIGHT), configuration: wkConfig)
        view.addSubview(webView)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = true
        // 添加进度条
        webView.addProgressView()
        // 监听title （其实进度和title都是用监听获取的）
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
    }
    
    // 监听title的回调
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "title") {
            if !NSString.isEmpty(self.webView.title) && NSString.isEmpty(self.titleStr) {
                self.addTitle(titleString: self.webView.title!)
            }
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "title")
    }

    // 加载页面
    func loadUrlRequest() {
        if !NSString.isEmpty(urlStr) {
            self.urlRequest = URLRequest.init(url: URL.init(string: urlStr!)!)
            webView.load(self.urlRequest!)
        } else if (!NSString.isEmpty(localPathStr)) {
            let path = Bundle.main.path(forResource: localPathStr!, ofType: "html")
            if let path = path {
                if IS_IOS9 {
                    let fileUrl = URL.init(fileURLWithPath: path)
                    if #available(iOS 9.0, *) {
                        webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl)
                    } else {
                        // Fallback on earlier versions
                        let fileUrl = try! self.fileURLForBuggyWKWebView8(fileURL: URL(fileURLWithPath: path))
                        urlRequest = URLRequest.init(url: fileUrl)
                        webView.load(urlRequest!)
                    }
                } else { // iOS8
                    let fileUrl = try! self.fileURLForBuggyWKWebView8(fileURL: URL(fileURLWithPath: path))
                    urlRequest = URLRequest.init(url: fileUrl)
                    webView.load(urlRequest!)
                }
            }
        }
    }
    
    // ios8加载本地资源
    func fileURLForBuggyWKWebView8(fileURL: URL) throws -> URL {
        // Some safety checks
        if !fileURL.isFileURL {
            throw NSError(
                domain: "BuggyWKWebViewDomain",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("URL must be a file URL.", comment:"")])
        }
        try! fileURL.checkResourceIsReachable()
        // Create "/temp/www" directory
        let fm = FileManager.default
        let tmpDirURL = URL(fileURLWithPath: kPathTemp).appendingPathComponent("www", isDirectory: true)
        try! fm.createDirectory(at: tmpDirURL, withIntermediateDirectories: true, attributes: nil)
        // Now copy given file to the temp directory
        let dstURL = tmpDirURL.appendingPathComponent(fileURL.lastPathComponent)
        let _ = try? fm.removeItem(at: dstURL)
        try! fm.copyItem(at: fileURL, to: dstURL)
        return dstURL
    }
    

}
