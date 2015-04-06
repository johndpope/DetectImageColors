//
//  PCCountedColor.swift
//  colortunes
//
//  Created by ERIC DEJONCKHEERE on 03/04/2015.
//  Copyright (c) 2015 Eric Dejonckheere. All rights reserved.
//

import Cocoa

class PCCountedColor: NSObject {

    var color: NSColor
    var count: NSInteger

    init(color: NSColor, count: NSInteger) {
        self.color = color
        self.count = count
        super.init()
    }

}
