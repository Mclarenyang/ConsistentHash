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
    //网络层
    var ring: Ring!
    
    func insertData(key: String , value: String) -> Int {return 2}
    func queryDataPD(key: String, hashKey: Int, isDelete: Bool) -> (Int,Bool) {return (2,true)}
    
}

struct data {
    
    var key: String
    var value: String
    var nodeNum: Int
    
}

class Node: SuperNode{
    
    //节点存储的数据 -> (k,v,nodeNum)
    private var storage = [data]()
    //投射的虚拟节点
    public var virtualNode = [Int]()
    //chord指针表
    public var finger = [Int]()
    
    //寻找节点--插入数据 --> 重写存储逻辑
    override func insertData(key: String , value: String) -> Int {
        let hashKey = key.consistentHash()
        //数据应该存储在本节点上
        if hashKey <= self.nodeNum && hashKey > finger[0]{
            print(insert(key: key, value: value, nodeNum: self.nodeNum))
            return 0
        }
        //数据存储超出finger的范围
        if hashKey > finger[finger.count-1]{
            ring.insert(key: key, value: value, nodeName: "", nodeNum: finger.last!, isFromVirtualNode: false)
            return 0
        }
        //数据应该存储在finger表中的节点上
        for index in (0..<finger.count-1).reversed(){
            if hashKey < finger[index]{
                ring.insert(key: key, value: value, nodeName: "", nodeNum: finger[index], isFromVirtualNode: false)
            }
        }
        return -1
    }
    
    //查找k下的v--打印&删除
    override func queryDataPD(key: String, hashKey: Int , isDelete: Bool) -> (Int,Bool) {
        if hashKey <= self.nodeNum && hashKey > finger[0]{
            for index in 0..<storage.count{
                let dataItem = storage[index]
                if dataItem.key == key{
                    print(dataItem)
                    if isDelete{
                        storage.remove(at: index)
                    }
                    return (nodeNum,true)
                }
            }
        }
        
        let hashKey = key.consistentHash()
        if hashKey > finger[finger.count-1]{
            ring.queryDataPD(key: key, nodeName: "", hashKey: finger.last!, isDelete: isDelete)
            return (0,true)
        }
        for index in (0..<finger.count-1).reversed(){
            if hashKey < finger[index]{
                ring.queryDataPD(key: key, nodeName: "", hashKey: finger[index], isDelete: isDelete)
                return (0,true)
            }
        }
        print("没有找到数据🤷‍♂️，k:\(key)")
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
        return true
    }
    
    //涉及节点删除后的数据重新分配
    func popData(nodeNum: Int){
        if finger.isEmpty{
            print("最后一个节点删除，所有数据丢失👋")
            return
        }
        if nodeNum == self.nodeNum{
            //分发所有数据
            for dataItem in storage{
                ring.insert(key: dataItem.key, value: dataItem.value, nodeName: "", nodeNum: finger[1], isFromVirtualNode: false)
            }
            //删除所有虚拟节点
            self.virtualNode.removeAll()
        }else{
            //分发数据
            for dataItem in storage{
                if dataItem.nodeNum == nodeNum{
                    ring.insert(key: dataItem.key, value: dataItem.value, nodeName: "", nodeNum: finger[1], isFromVirtualNode: false)
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
    
}
