//
//  node.swift
//  ConsistentHash
//
//  Created by 杨键 on 2018/12/23.
//  Copyright © 2018 杨键. All rights reserved.
//

import Foundation

class SuperNode {
    
    //节点哈希值
    public var nodeNum = 0
    //节点名称
    public var nodeName = ""
    //chord指针表
    public var finger = [Int](){
        didSet{
            //排序
            self.finger = finger.sorted(by: <)
        }
    }
    //网络层
    var ring: Ring!
    //请求标识符
    var requestID = ""
    
    func insertData(key: String , value: String, requestID: String) -> Int {return 2}
    func queryDataPD(key: String, hashKey: Int, isDelete: Bool, requestID: String) -> (Int,Bool) {return (2,true)}
    
}

struct data {
    
    var key: String
    var value: String
    var nodeNum: Int
    
}

class Node: SuperNode{
    
    //节点存储的数据 -> (k,v,nodeNum)
    private var storage = [data](){
        didSet{
            self.storageCount = storage.count
            if middleValueHash >= 0{
                self.middleValueHash = storage[Int(storageCount/2)].key.consistentHash()
            }
        }
    }

    public var storageCount = 0
    public var middleValueHash = 0
    //投射的虚拟节点
    public var virtualNode = [Int]()
    //真实节点即将被删除
    private var ifWillBeDelete = false
    
    private var timer = Timer()
    
    //寻找节点--插入数据
    override func insertData(key: String , value: String, requestID: String) -> Int {
        //如果节点将要被删除，那么第二次到达时直接投递
        if self.ifWillBeDelete {
            ring.insert(key: key, value: value, nodeName: "", nodeNum: finger[Int(arc4random()) % finger.count], isFromVirtualNode: false, requestID: requestID)
            return 0
        }
        let hashKey = key.consistentHash()
        
        //数据应该存储在本节点上
        if self.requestID == requestID{
            _ = insert(key: key, value: value, nodeNum: self.nodeNum)
            return 0
        }
        
        //数据存储超出finger的范围
        if hashKey > finger[finger.count-1] || hashKey < finger[0]{
            self.requestID = requestID
            ring.insert(key: key, value: value, nodeName: "", nodeNum: finger.last!, isFromVirtualNode: false, requestID: requestID)
            return 0
        }
        
        //存储在指针表中的节点中
        for index in (1..<finger.count).reversed(){
            if hashKey <= finger[index] && hashKey > finger[index-1]{
                if finger[index] == self.nodeNum{
                    _ = insert(key: key, value: value, nodeNum: self.nodeNum)
                }else{
                    self.requestID = requestID
                    ring.insert(key: key, value: value, nodeName: "", nodeNum: finger[index], isFromVirtualNode: false, requestID: requestID)
                }
                break
            }
        }
        return -1
    }
    
    //查找k下的v--打印&删除
    override func queryDataPD(key: String, hashKey: Int , isDelete: Bool, requestID: String) -> (Int,Bool) {
        NSLog("\(nodeName)+\(key)")
        if query(key: key, hashKey: hashKey, isDelete: isDelete) {return(0,true)}
        if requestID == self.requestID{
            print("没有找到数据🤷‍♂️，k:\(key),\(nodeName)")
            return (-1,false)
        }
        
        let hashKey = key.consistentHash()
        if hashKey > finger[finger.count-1] || hashKey < finger[0]{
            self.requestID = requestID
            ring.queryDataPD(key: key, nodeName: "", hashKey: finger.last!, isDelete: isDelete, requestID: requestID)
            return (0,true)
        }
        
        for index in (0..<finger.count).reversed(){
            if hashKey <= finger[index] && hashKey > finger[index-1]{
                self.requestID = requestID
                ring.queryDataPD(key: key, nodeName: "", hashKey: finger[index], isDelete: isDelete, requestID: requestID)
                return (0,true)
            }
        }
        return (-1,false)
    }
    
    //批量打印数据
    func printAllOfTheData(nodeNum: Int) -> Int{
        if nodeNum == self.nodeNum {
            for dataItem in storage {
                print(dataItem)
            }
        }else{
            for dataItem in storage {
                if dataItem.nodeNum == nodeNum{
                    print(dataItem.key)
                }
            }
        }
        return 1
    }
    
    //本地插入
    func insert(key: String, value: String, nodeNum: Int) -> Bool{
        let dataItem = data(key: key, value: value, nodeNum: nodeNum)
        storage.append(dataItem)
        print("数据存储->k-v:\(key)-\(value),in: \(nodeName)")
        self.requestID = String(Int(arc4random()))
        return true
    }
    
    //本地查找
    func query(key: String, hashKey: Int , isDelete: Bool) -> Bool{
        for index in 0..<storage.count{
            let dataItem = storage[index]
            if dataItem.key == key{
                if isDelete{
                    storage.remove(at: index)
                    print("数据删除->key:\(key),from: \(nodeName)")
                }else{
                    print("\(dataItem),in: \(nodeName)")
                }
                self.requestID = String(Int(arc4random()))
                return true
            }
        }
        return false
    }
    
    //计时器刷新 - 未使用
    func freeRequest(key: String) {
        self.requestID = key
        let queue = DispatchQueue(label: "consistentHash.mclarenyang", attributes: .concurrent)
        queue.async {
            sleep(1)
            self.requestID = String(Int(arc4random()))
        }
        sleep(2)
    }
    
    //涉及节点删除后的数据重新分配
    func popData(nodeNum: Int){
        if finger.isEmpty{
            print("最后一个节点删除，所有数据丢失👋")
            return
        }
        
        self.ifWillBeDelete = true
        
        if nodeNum == self.nodeNum{
            //分发所有数据
            for dataItem in storage{
                ring.insert(key: dataItem.key, value: dataItem.value, nodeName: "", nodeNum: finger[2], isFromVirtualNode: false, requestID: "")
            }
            //删除所有虚拟节点
            self.virtualNode.removeAll()
        }else{
            //分发数据
            for dataItem in storage{
                if dataItem.nodeNum == nodeNum{
                    ring.insert(key: dataItem.key, value: dataItem.value, nodeName: "", nodeNum: finger[2], isFromVirtualNode: false, requestID: String(Int(arc4random())))
                }
            }
            //删除这个虚拟节点
            for index in 0..<virtualNode.count{
                if virtualNode[index] == nodeNum{
                    virtualNode.remove(at: index)
                }
            }
        }
    }
    
    //refresh后的数据更新
    func popRedundantData(VirtualNodeNum: Int){
        for index in (Int(storageCount/2)..<storageCount).reversed(){
            let dataItem = storage[index]
            ring.insert(key: dataItem.key, value: dataItem.value, nodeName:"", nodeNum: VirtualNodeNum, isFromVirtualNode: false, requestID: String(Int(arc4random())))
            //负载均衡掉的数据删除
            self.storage.remove(at: index)
        }
    }
}
