//
//  main.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/16.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

// todo
// 2. Add Primitives like 'Greater'
// n. bignum?

import Foundation
import mintlisp

func input() -> NSString? {
    var keyboard = NSFileHandle.fileHandleWithStandardInput()
    var inputData = keyboard.availableData
    return NSString(data: inputData, encoding:NSUTF8StringEncoding)
}

var interpreter = Interpreter()
var isLoop = true

//REPL

while isLoop {
    let a = input()
    
    let timewatch = NSDate()
    
    if a == "(quit)\n" {
        isLoop = false
    }
    
    if let chr = a as? String {
        
        let exp = interpreter.readln(chr)
        let res = interpreter.eval(exp.uid)
        println(exp._debug_string())
        println("sec: \(-timewatch.timeIntervalSinceNow)")
        println(res.str("  ", level: 1))
    }
}

