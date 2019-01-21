# ConsistentHash
Chord consistent hashing ring by Swift 4.2

## 概述
---
&emsp;此 project 为模拟一致性哈希环（chord环）的实现，代码中已经有较为详细的注释，可以直接参看代码结构及架构说明对照理解，同时建议在此之前先理解一致性哈希及 chord 环，详见[文档](https://github.com/dmclNewbee302/DMCL-2018)。
&emsp;如果发现实现中的 bug，或者想要完成下面未完成的工作，欢迎访问本项目的 [GitHub](https://github.com/Mclarenyang/ConsistentHash)。🙋🙋‍♂️

## 完成情况
ᕕ( ᐛ )ᕗ
- [x] 真实节点的增删
- [x] 数据增删查
- [x] 删除节点后的数据分发
- [x] chord 环指针表
- [x] 虚拟节点版本（半自动负载均衡）

ToDo
- [ ] 自动化负载均衡
- [ ] 节点多线程任务
- [ ] 可视化与交互

这里提供一些还未完成的点的实现思路：
- 自动化负载均衡：只用在节点类中定义一个阈值参数，当存储量达到参数时候调用已经实现的半自动的负载均衡方法就行。同时阈值参数还能够根据节点的性能灵活配置，使模拟实现更加贴近现实。
- 节点多线程任务：在现有版本的基础上将相关任务方法在执行的时候开一个线程，线程标示设定为 requestID ，节点类中的 requestID 成员变量改用数组存储。

## 代码结构
```
ConsistentHash
│   README.md
│   ConsistentHash.xcodeproj    //xcode 项目文件
└───ConsistentHash
│   main.swift              //测试文件
│   ring.swift              //Ring 类、String MD5 加密扩展
│   node.swift              //节点父类、真实节点类
│   node_virtual.swift      //虚拟节点类
└───*
```
