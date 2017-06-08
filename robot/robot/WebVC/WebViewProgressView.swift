//
//  WebViewProgressView.swift
//  WKWebViewProgressView
//
//  Created by LZios on 16/3/3.
//  Copyright © 2016年 LZios. All rights reserved.
//

import UIKit
import WebKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class WebViewProgressView: UIView {
    var superWebView: WKWebView?
    var topY: CGFloat? = 0
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let webView = newSuperview as? WKWebView {
            superWebView = webView
            superWebView?.addObserver(self, forKeyPath: "estimatedProgress", options: [.new, .old], context: nil)
            superWebView?.scrollView.addObserver(self, forKeyPath: "contentInset", options: [.new, .old], context: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let webView = object as? WKWebView {
            if webView == superWebView && keyPath == "estimatedProgress" {
                self.animateLayerPosition(keyPath)
            }
        }
        if let scrollView = object as? UIScrollView {
            if scrollView == superWebView?.scrollView && keyPath == "contentInset" {
                
                self.animateLayerPosition(keyPath)
            }
            
        }
        print(superWebView?.estimatedProgress ?? 0.0)
    }
    
    override func layoutSubviews() {
        
    }
    
    func animateLayerPosition(_ keyPath: String?) {
        
        if keyPath == "estimatedProgress" {
            self.isHidden = false
        }else if keyPath == "contentInset" {
            topY = superWebView?.scrollView.contentInset.top
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
            self.frame = CGRect(x: 0, y: self.topY!, width: (self.superWebView?.bounds.width)! * CGFloat((self.superWebView?.estimatedProgress)!), height: 3)
            }, completion: { (finished) -> Void in
                if self.superWebView?.estimatedProgress >= 1 {
                    self.isHidden = true
                    self.frame = CGRect(x: 0, y: self.topY!, width: 0, height: 3)
                }
        })
    }
    
    deinit {
        superWebView?.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
        superWebView?.scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}

public let GDBProgressViewTag = 214356312

extension WKWebView {
    fileprivate var progressView: UIView? {
        get {
            let progressView = viewWithTag(GDBProgressViewTag)
            return progressView
        }
    }
    
    public func addProgressView() {
        if progressView == nil {
            let view = WebViewProgressView()
            view.frame = CGRect(x: 0, y: 64, width: 0, height: 3)
            view.backgroundColor = UIColor.getMainColorSwift()
            view.tag = GDBProgressViewTag
            view.autoresizingMask = .flexibleWidth
            self.addSubview(view)
        }
    }
}
