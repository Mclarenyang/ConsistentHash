//
//  main.swift
//  ConsistentHash
//
//  Created by 杨键 on 2018/12/24.
//  Copyright © 2018 杨键. All rights reserved.
//

import Foundation

print("no".consistentHash())

let consistentHashRing = Ring()
consistentHashRing.printNode()
_ = consistentHashRing.addRealNode(nodeName: "node1")
_ = consistentHashRing.addRealNode(nodeName: "node3")
_ = consistentHashRing.addRealNode(nodeName: "node2")
consistentHashRing.printNode()

_ = consistentHashRing.deleteNode(nodeName: "node1", isRealNode: true)
consistentHashRing.printNode()

//consistentHashRing.insert(key: "神仙", value: "打架", nodeName: "node1", nodeNum: -1, isFromVirtualNode: false)
//consistentHashRing.insert(key: "写的", value: "什么玩意", nodeName: "node2", nodeNum: -1, isFromVirtualNode: false)
//consistentHashRing.queryDataPD(key: "神仙", nodeName: "node2", hashKey: -1, isDelete: false)
//consistentHashRing.queryDataPD(key: "神仙", nodeName: "node1", hashKey: -1, isDelete: false)
//consistentHashRing.queryDataPD(key: "神仙", nodeName: "node3", hashKey: -1, isDelete: false)





