//
//  MoreVC.swift
//  robot
//
//  Created by zhangmingwei on 2017/6/2.
//  Copyright © 2017年 niaoyutong. All rights reserved.
//

import UIKit

class MoreVC: SwifBaseViewController,UITableViewDelegate,UITableViewDataSource {
    
    var tableView: UITableView!
    var dataArr: NSMutableArray!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitle(titleString: NSLocalizedString("说明书", comment: ""))
        self.initTableViewAndData()
    }
    
    func initTableViewAndData() {
        dataArr = NSMutableArray()
        dataArr.append("提问问题功能：日常生活问题（支持语音播放~）")
        dataArr.append("提问天气功能：今天天气或明天天气（支持语音播放~）")
        dataArr.append("网页搜索功能：首页右上角（这里也支持语音播放哟~）")
        dataArr.append("词句翻译功能：早上好用英语怎么说（目前只支持英语）")
        dataArr.append("重复播放功能：重读一次/重复一次")
        
        tableView = UITableView(frame: CGRect.init(x: 0, y: NAVIGATIONBAR_HEIGHT, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - NAVIGATIONBAR_HEIGHT), style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.register(MoreCell.classForCoder(), forCellReuseIdentifier: "MoreCell")
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0.1))
        tableView.sectionFooterHeight = 0.1
    }
    
    // MARK: 表格代理相关
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let str = dataArr.object(at: indexPath.row) as! String
        let height = str.sizeFor(size: CGSize.init(width: SCREEN_WIDTH - 20, height: 999), font: FONT_PingFang(fontSize: 14)).height
        return height + 30
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MoreCell", for: indexPath) as! MoreCell
        
        cell.nameLbl?.text = dataArr.object(at: indexPath.row) as? String
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
       
    }
}
