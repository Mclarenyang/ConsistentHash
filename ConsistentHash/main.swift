//
//  main.swift
//  ConsistentHash
//
//  Created by 杨键 on 2018/12/24.
//  Copyright © 2018 杨键. All rights reserved.
//

import Foundation


let CR = Ring.shared
CR.power = 32

//consistentHashRing.printNode()
_ = CR.addRealNode(nodeName: "node1")
_ = CR.addRealNode(nodeName: "node3")
_ = CR.addRealNode(nodeName: "node2")
CR.printNode()

//_ = consistentHashRing.deleteNode(nodeName: "node1", isRealNode: true)
//consistentHashRing.printNode()

CR.insert(key: "神仙", value: "打架", nodeName: "node1", nodeNum: -1, isFromVirtualNode: false, requestID: "")
CR.insert(key: "写的", value: "什么玩意", nodeName: "node2", nodeNum: -1, isFromVirtualNode: false, requestID: "")

CR.rebBalance()
CR.printNode()


CR.queryDataPD(key: "神仙", nodeName: "node2", hashKey: -1, isDelete: false, requestID: "")
CR.queryDataPD(key: "写的", nodeName: "node3", hashKey: -1, isDelete: false, requestID: "")
CR.queryDataPD(key: "写的", nodeName: "node2", hashKey: -1, isDelete: false, requestID: "")

_ = CR.deleteNode(nodeName: "virtual-node2", isRealNode: false)
CR.printNode()

CR.queryDataPD(key: "写的", nodeName: "node3", hashKey: -1, isDelete: true, requestID: "")
CR.queryDataPD(key: "写的", nodeName: "node3", hashKey: -1, isDelete: false, requestID: "")

_ = CR.deleteNode(nodeName: "node3", isRealNode: true)
CR.printNode()
CR.queryDataPD(key: "神仙", nodeName: "node2", hashKey: -1, isDelete: false, requestID: "")






