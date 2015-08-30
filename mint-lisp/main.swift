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

func input() -> NSString? {
    var keyboard = NSFileHandle.fileHandleWithStandardInput()
    var inputData = keyboard.availableData
    return NSString(data: inputData, encoding:NSUTF8StringEncoding)
}

var global = Env()
global.hash_table = global_environment()
var isLoop = true

//REPL

while isLoop {
    let a = input()
    let e = Evaluator()
    
    let timewatch = NSDate()
    
    if a == "(quit)\n" {
        isLoop = false
    }
    
    if let chr = a as? String {
        let tokens = lispTokenizer([Character](chr))
        if let (r, s) = tokens.first {
            let parser = parseLispExpr()
            //println(r)
            for (r, s) in parser(r) {
                println(r._debug_string())
                println(e.eval(r, gl_env: global)._debug_string())
                println("sec: \(-timewatch.timeIntervalSinceNow)")
            }
        }
    }
}

