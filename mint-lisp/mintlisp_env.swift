//
//  mintlisp_env.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/03.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class Env {
    var hash_table = [String: SExpr]()
    var ext_env: Env?
    
    init() {
        ext_env = nil
    }
    
    func lookup(key : String) -> SExpr {
        if let value = hash_table[key] {
            return value
        } else {
            if let eenv = ext_env {
                return eenv.lookup(key)
            } else {
                println("Unbouded symbol")
                return MNull()
            }
        }
    }
    
    // todo: variable length of arguments
    func extended_env(symbols: [SExpr], values: [SExpr]) -> Env? {
        let _env = Env()
        _env.ext_env = self
        
        if symbols.count == values.count {
            for var i = 0; symbols.count > i; i++ {
                if let symbol = symbols[i] as? MSymbol {
                    _env.define_variable(symbol.key, val: values[i])
                } else {
                    println("Unproper parameter values")
                    return nil
                }
            }
        } else {
            println("Err. Number of Symbol and Value is unmatch.")
            return nil
        }
        
        return _env
    }
    
    func clone() -> Env {
        let cloned_env = Env()
        cloned_env.ext_env = self.ext_env
        cloned_env.hash_table = self.hash_table
        return cloned_env
    }
    
    func define_variable(key: String, val: SExpr) -> Bool {
        if hash_table[key] == nil {
            hash_table[key] = val
            return true
        } else {
            return false
        }
    }
    
    func set_variable(key: String, val: SExpr) -> Bool {
        if hash_table[key] == nil {
            return false
        } else {
            hash_table[key] = val
            return true
        }
    }
}

func global_environment() -> [String : SExpr] {
    var primitives = [String : SExpr]()
    
    primitives["+"] = Plus()
    primitives["-"] = Minus()
    primitives["*"] = Multiply()
    primitives["/"] = Divide()
    primitives["="] = isEqual()
    //primitives[">"] = isEqual()
    //primitives["<"] = isEqual()
    //primitives["<="] = isEqual()
    //primitives[">="] = isEqual()
    //primitives["cons"] = isEqual()
    primitives["car"] = Car()
    primitives["cdr"] = Cdr()
    primitives["caar"] = Caar()
    primitives["cadr"] = Cadr()
    primitives["cdar"] = Cdar()
    primitives["cddr"] = Cddr()
    primitives["caaar"] = Caaar()
    primitives["caadr"] = Caadr()
    primitives["caddr"] = Caddr()
    primitives["cdddr"] = Cdddr()
    primitives["cdaar"] = Cdaar()
    primitives["cddar"] = Cddar()
    primitives["cdadr"] = Cdadr()
    primitives["cadar"] = Cadar()
    primitives["null"] = MNull()
    //primitives["list"] = isEqual()
    //primitives["apply"] = isEqual()
    //primitives["map"] = isEqual()
    primitives["println"] = Print()

    return primitives
}