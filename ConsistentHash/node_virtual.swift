//
//  node_virtual.swift
//  ConsistentHash
//
//  Created by 杨键 on 2018/12/23.
//  Copyright © 2018 杨键. All rights reserved.
//

import Foundation

class Node_Virtual: SuperNode{
    
    //所属于的真实节点hash值
    public var realNodeNum = 0
    
    //寻找节点--插入数据
    override func insertData(key: String , value: String) -> Int {
        let hashKey = key.consistentHash()
        //数据应该存储在本节点上
        if hashKey <= self.nodeNum && hashKey > finger[0]{
            ring.insert(key: key, value: value, nodeName: "", nodeNum: realNodeNum, isFromVirtualNode: true)
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
    override func queryDataPD(key: String, hashKey: Int, isDelete: Bool) -> (Int,Bool) {
        if hashKey <= self.nodeNum && hashKey > finger[0]{
            //调用真实节点的查找及删除，--->修改数据hash
            ring.queryDataPD(key: key, nodeName: "", hashKey: realNodeNum, isDelete: isDelete)
            return (1,true)
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
        return (-1,false)
    }
    
    //打印映射到这个虚拟节点的数据 -- 返向调用真实节点
    func printVirtualNodeData() {
        ring.printData(nodeName: "", nodeNum: realNodeNum, virtualNodeNum: self.nodeNum, isFromVirtualNode: true)
    }
}
