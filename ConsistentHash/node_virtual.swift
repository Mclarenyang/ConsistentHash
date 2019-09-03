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
    override func insertData(key: String, value: String, requestID: String) -> Int {
        let hashKey = key.consistentHash()

        //数据应该存储在本节点上
        if self.requestID == requestID{
            ring.insert(key: key, value: value, nodeName: "", nodeNum: realNodeNum, isFromVirtualNode: true, requestID: requestID)
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
                    ring.insert(key: key, value: value, nodeName: "", nodeNum: realNodeNum, isFromVirtualNode: true, requestID: requestID)
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
    override func queryDataPD(key: String, hashKey: Int, isDelete: Bool, requestID: String) -> (Int,Bool) {
        //是否在真实节点上
        if hashKey == self.nodeNum{
            //调用真实节点的查找及删除，--->修改数据hash
            ring.queryDataPD(key: key, nodeName: "", hashKey: realNodeNum, isDelete: isDelete, requestID: requestID)
            return (1,true)
        }

        let hashKey = key.consistentHash()
        if hashKey > finger[finger.count-1] || hashKey < finger[0]{
            self.requestID = requestID
            ring.queryDataPD(key: key, nodeName: "", hashKey: finger.last!, isDelete: isDelete, requestID: requestID)
            return (0,true)
        }

        for index in (0..<finger.count-1).reversed(){
            if hashKey <= finger[index] && hashKey > finger[index-1]{
                self.requestID = requestID
                ring.queryDataPD(key: key, nodeName: "", hashKey: finger[index], isDelete: isDelete, requestID: requestID)
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
