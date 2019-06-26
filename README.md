# ConsistentHash
![Xcode 10.0+](https://img.shields.io/badge/Xcode-10.0%2B-blue.svg)
![Swift 4.2+](https://img.shields.io/badge/Swift-4.2%2B-orange.svg)

English | [简体中文](./README_CHI.md)

## Introduction
&emsp; This project is an implementation of the simulation consistency hash ring (chord ring). There are already more detailed comments in the code. You can directly refer to the code structure and architecture description for comparison. It is recommended to understand the consistency hash and chord ring before this, see [here](https://en.wikipedia.org/wiki/Chord_(peer-to-peer)) for more details.

&emsp;If you find any bugs, or if you want to complete the unfinished work below, you are welcome to submit a Issue or Fork code.🙋🙋‍♂️

## Feature Completion
ᕕ( ᐛ )ᕗ
- [x] Additions and deletions of real nodes
- [x] Data addition and deletion
- [x] Data distribution after deleting a node
- [x] Chord ring pointer table
- [x] Virtual node version (semi-automatic load balancing)

ToDo
- [ ] Automated load balancing
- [ ] Node multi-threaded task
- [ ] Visualization and interaction

Here are some ideas for implementing points that have not yet been completed:
- Automated load balancing: Only define a threshold parameter in the node class, and call the semi-automatic load balancing method that has been implemented when the storage amount reaches the parameter. At the same time, the threshold parameters can be flexibly configured according to the performance of the nodes, making the simulation implementation more realistic.
- Node multi-threaded task: On the basis of the existing version, the related task method is opened at the time of execution, the thread flag is set to requestID, and the requestID member variable in the node class is changed to the array storage.

## Code structure
```
ConsistentHash
│   README.md
│   ConsistentHash.xcodeproj    //Xcode project file
└───ConsistentHash
    │   main.swift              //Test file
    │   ring.swift              //Ring class、String MD5 extension
    │   node.swift              //Node superClass、real node class
    │   node_virtual.swift      //Virtual node class
    └───*
```

