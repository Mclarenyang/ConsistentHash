//
//  ring.swift
//  ConsistentHash
//
//  Created by 杨键 on 2018/12/23.
//  Copyright © 2018 杨键. All rights reserved.
//

import Foundation
import CommonCrypto

class Ring {
    
    //哈希环
    public var ring = [SuperNode]()
    
    //-----用户接口-----//
    //添加真实节点
    func addRealNode(nodeName: String) -> Int {
        
        let nodeHash = nodeName.consistentHash()
        let newNode = Node()
        newNode.nodeName = nodeName
        newNode.nodeNum = nodeHash
        newNode.ring = self
        
        if ring.count == 0{
            ring.append(newNode)
            return nodeHash
        }
        
        for index in 0..<ring.count {
            if nodeHash <= ring[index].nodeNum ||
                index+1 == ring.count{
                ring.insert(newNode, at: index)
                return nodeHash
            }
        }
        return -1
    }
    
    //删除节点
    func deleteNode(nodeName: String, isRealNode: Bool) -> Bool {
        if ring.isEmpty {
            return false
        }
        for index in 0..<ring.count{
            if nodeName == ring[index].nodeName{
                //真实节点删除
                if isRealNode{
                    let realNode = ring[index] as! Node
                    //删除真实节点连接的所有虚拟节点
                    deleteAllVirtualNodeforRealNode(realNode: realNode)
                    _ = (ring[index] as! Node).popData(nodeNum: nodeName.consistentHash())
                    //todo--更新node指针表
                    ring.remove(at: index)
                    return true
                }else{
                    //告诉真实节点它的虚拟节点被删除了
                    let realNodeNum = (ring[index] as! Node_Virtual).realNodeNum
                    for realNode in ring{
                        if realNodeNum == (realNode as! Node).nodeNum{
                            _ = (realNode as! Node).popData(nodeNum: nodeName.consistentHash())
                        }
                    }
                    ring.remove(at: index)
                    //todo--更新node指针表
                    return true
                }
            }
        }
        return false
    }
    
    //删除真实节点下的所有虚拟节点
    func deleteAllVirtualNodeforRealNode(realNode: Node){
        for virtualNodeNum in realNode.virtualNode{
            for index in 0..<ring.count{
                if ring[index].nodeNum == virtualNodeNum{
                    ring.remove(at: index)
                }
            }
        }
    }
    
    //负载均衡 -> 自动添加虚拟节点
    //todo
    
    //打印现在的节点状态
    func printNode() {
        if ring.isEmpty {
            print("当前没有节点")
        }else{
            var nodeStr = "👉"
            for node in ring{
                nodeStr += node.nodeName
                nodeStr += "->"
            }
            nodeStr += "🙌"
            print(nodeStr)
        }
    }
    
    //打印节点数据
    func printData(nodeName: String, nodeNum: Int, virtualNodeNum:Int, isFromVirtualNode: Bool){
        for node in ring {
            if node.nodeName == nodeName || node.nodeNum == nodeNum{
                if isFromVirtualNode{
                    _ = (node as! Node).printAllOfTheData(nodeNum: virtualNodeNum)
                }else{
                    _ = (node as! Node).printAllOfTheData(nodeNum: nodeNum)
                }
            }
        }
    }
    
    //打印虚拟节点数据
    func printVirtualData(nodeName: String){
        for node in ring {
            if node.nodeName == nodeName{
                _ = (node as! Node_Virtual).printVirtualNodeData()
            }
        }
    }
    
    
    //-----网络层-----//
    //更新finger指针
    func refreshFinger() {
        //todo
    }
    
    //data_数据插入，兼容用户接口
    func insert(key: String , value: String, nodeName: String, nodeNum:Int, isFromVirtualNode: Bool){
        for node in ring {
            if node.nodeName == nodeName || node.nodeNum == nodeNum{
                if isFromVirtualNode{
                    print((node as! Node).insert(key: key, value: value, nodeNum: nodeNum))
                }else{
                    _ = node.insertData(key: key, value: value)
                }
            }
        }
    }
    
    //data_数据查找--删除，兼容用户接口
    func queryDataPD(key: String, nodeName: String, hashKey: Int, isDelete: Bool){
        for index in 0..<ring.count {
            if ring[index].nodeName == nodeName || ring[index].nodeNum >= hashKey {
                _ = ring[index].queryDataPD(key: key, hashKey: hashKey, isDelete: isDelete)
            }
        }
    }
}

extension String {
    func consistentHash() -> Int{
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0..<digestLen{
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        let hashValue = String(format: hash as String)
        var hashResult = 0
        for index in 0..<4{
            let indexHead = hashValue.index(hashValue.startIndex, offsetBy: index * 4)
            let indexBottom = hashValue.index(hashValue.startIndex, offsetBy: index * 4 + 8)
            hashResult |= Int(hashValue[indexHead..<indexBottom], radix: 16)!
        }
        return hashResult
    }
}
