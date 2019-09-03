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

    static let shared = Ring()
    private init(){}

    //哈希环
    private var ring = [SuperNode]()

    //哈希环的大小，2的power幂
    public var power = 0

    //-----用户接口-----//
    //添加真实节点
    func addRealNode(nodeName: String) -> Int {

        let nodeHash = nodeName.consistentHash()
        let newNode = Node()
        newNode.nodeName = nodeName
        newNode.nodeNum = nodeHash
        newNode.ring = Ring.shared

        if ring.count == 0{
            ring.append(newNode)
            return nodeHash
        }

        for index in 0..<ring.count {
            if nodeHash <= ring[index].nodeNum ||
                index+1 == ring.count{
                ring.insert(newNode, at: index)
                refreshFinger()
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
                    _ = realNode.popData(nodeNum: nodeName.consistentHash())

                    ring.remove(at: index)
                    print("删除节点成功:\(nodeName)")
                    refreshFinger()
                    return true
                }else{
                    //告诉真实节点它的虚拟节点被删除了
                    let realNodeNum = (ring[index] as! Node_Virtual).realNodeNum
                    for realNode in ring{
                        if realNodeNum == realNode.nodeNum{
                            _ = (realNode as! Node).popData(nodeNum: nodeName.consistentHash())
                        }
                    }
                    ring.remove(at: index)
                    refreshFinger()
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
    func rebBalance() {
        /*
         * 1 找出存储最多的节点及存储最少的节点
         * 2 找出最大存储量节点的数据hash中间值
         * 3 new一个虚拟节点将hash值设置为中间值 名称为virtual（num）
         * 4 将虚拟节点链接到存储最小的真实节点上
         * 5 触发更新指针表/触发数据重新分配
         */

        var max = (0,Node())
        var min = (1<<32,Node())
        var maxNodeIndex = 0
        //1
        for index in 0..<ring.count{
            //a.hasPrefix("Hel")
            if ring[index].nodeName.hasPrefix("virtual"){continue}
            let realNode = ring[index] as! Node
            if max.0 < realNode.storageCount{
                max = (realNode.storageCount, realNode)
                maxNodeIndex = index

            }
            if min.0 > realNode.storageCount{
                min = (realNode.storageCount, realNode)
            }
        }
        if min.0 == max.0 || min.1.nodeNum == max.1.nodeNum{
            return
        }
        //2
        let middleHash = max.1.middleValueHash
        //3
        let virtualNode = Node_Virtual()
        virtualNode.nodeNum = middleHash
        virtualNode.nodeName = "virtual-" + min.1.nodeName
        //4
        virtualNode.realNodeNum = min.1.nodeNum
        virtualNode.ring = self
        min.1.virtualNode.append(virtualNode.nodeNum)
        ring.insert(virtualNode, at: maxNodeIndex)
        //5
        refreshFinger()
        max.1.popRedundantData(VirtualNodeNum: virtualNode.nodeNum)
    }

    //打印现在的节点状态
    func printNode() {
        if ring.isEmpty {
            print("当前没有节点")
        }else{
            var nodeStr = "⭕️"
            for node in ring{
                nodeStr += node.nodeName
                nodeStr += "->"
            }
            nodeStr += "⭕️"
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
    private func refreshFinger() {
        //如果当前只有一个节点
        if ring.count == 1{return}

        for index in 0..<ring.count{
            var finger = [Int]()
            //先将前驱加入
            if index-1 < 0 {
                finger.append((ring.last?.nodeNum)!)
            }else{
                finger.append(ring[index-1].nodeNum)
            }

            //如果现在的节点数小于幂的量-->没有必要建立跳跃的指针表
            if ring.count+1 <= power{
                for count in 0..<ring.count{
                    if count+index > ring.count-1{
                        let i = count + index - ring.count
                        finger.append(ring[i].nodeNum)
                    }else{
                        finger.append(ring[count+index].nodeNum)
                    }
                }
                ring[index].finger.removeAll()
                ring[index].finger = finger
                continue
            }

            let nowNodeNum = ring[index].nodeNum
            for row in 0..<power{
                var 🎯 = nowNodeNum + (1<<row)
                if 🎯 > (ring.last?.nodeNum)!{
                    🎯 = 🎯 - 1<<power
                }
                for j in 0..<ring.count{
                    if ring[j].nodeNum > 🎯{
                        finger.append(ring[j].nodeNum)
                    }
                }
            }

            ring[index].finger.removeAll()
            ring[index].finger = finger
        }
    }

    //data_数据插入，兼容用户接口
    func insert(key: String , value: String, nodeName: String, nodeNum:Int, isFromVirtualNode: Bool, requestID: String){
        var nowRequestID = requestID
        if requestID == "" {
            nowRequestID = String(Int(arc4random()))
        }
        for node in ring {
            if node.nodeName == nodeName || node.nodeNum == nodeNum{
                if isFromVirtualNode{
                    print((node as! Node).insert(key: key, value: value, nodeNum: nodeNum))
                    return
                }else{
                    _ = node.insertData(key: key, value: value, requestID: nowRequestID)
                    return
                }
            }
        }
        print("没有找到你请求的节点🤨-nodeName:\(nodeName) nodeNum:\(nodeNum)")
    }

    //data_数据查找--删除，兼容用户接口
    func queryDataPD(key: String, nodeName: String, hashKey: Int, isDelete: Bool, requestID: String){
        var nowRequestID = requestID
        if requestID == "" {
            nowRequestID = String(Int(arc4random()))
        }
        for index in 0..<ring.count {
            //命名优先
            if ring[index].nodeName != nodeName && hashKey < 0 {
                continue
            }

            if ring[index].nodeName == nodeName {
                _ = ring[index].queryDataPD(key: key, hashKey: hashKey, isDelete: isDelete, requestID: nowRequestID)
                return
            }

            if ring[index].nodeNum == hashKey && hashKey > 0{
                _ = ring[index].queryDataPD(key: key, hashKey: hashKey, isDelete: isDelete, requestID: nowRequestID)
                return
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
            hashResult += Int(hashValue[indexHead..<indexBottom], radix: 16)! % (1<<32 / 4)
        }
        return hashResult
    }
}
