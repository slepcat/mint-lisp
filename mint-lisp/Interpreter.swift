//
//  Interpreter.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/31.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class Interpreter {
    
    var trees:[SExpr] = []
    let global: Env
    
    var indent: String = "  "
    
    init() {
        global = Env()
        global.hash_table = global_environment()
    }
    
    let evaluator = Evaluator()
    
    ///// Interpreter /////
    
    func readln(rawstr: String) -> SExpr {
        return MNull.staticNull
    }
    
    func readfile(fileContent: String) {
        
    }
    
    func preprocess(uid: UInt) -> SExpr {
        
        // todo
        
        return lookup(uid).target
    }
    
    func eval(uid: UInt) -> SExpr {
        return evaluator.eval(preprocess(uid), gl_env:global)
    }
    
    ///// Manipulating S-Expression /////
    
    func new(rawstr: String) -> UInt? {
        //let expr = readlin(rawstr)
        
        return nil//failed to add exp
    }
    
    func lookup(uid: UInt) -> (conscell: SExpr, target: SExpr) {
        for exp in trees {
            let res = exp.lookup_exp(uid)
            if !res.target.isNull() {
                return res
            }
        }
        
        return (MNull.staticNull, MNull.staticNull)
    }
    
    func add(uid: UInt, rawstr: String) -> UInt? {
        
        return nil//failed to add arg
    }
    
    func remove(uid: UInt) {
        
        for var i = 0; trees.count > i; i++ {
            let res = trees[i].lookup_exp(uid)
            if !res.target.isNull() {
                
                let opds = delayed_list_of_values(res.target)
                
                if res.conscell.isNull() {
                    trees.removeAtIndex(i)
                    
                    for exp in opds {
                        if let pair = exp as? Pair {
                            trees.append(pair)
                        }
                    }
                    
                } else {
                    if let pair = res.conscell as? Pair {
                        if pair.cdr.isNull() {
                            remove(pair.uid)
                        } else {
                            if let nextPair = pair.cdr as? Pair {
                                pair.car = nextPair.car
                                pair.cdr = nextPair.cdr
                            } else {
                                pair.car = pair.cdr
                                pair.cdr = MNull()
                            }
                        }
                    } else {
                        println("fail to remove. bad conscell")
                    }
                }
                break
            }
        }
    }
    
    func overwrite(uid: UInt, rawstr: String) {
        let res = lookup(uid)
        if let pair = res.conscell as? Pair {
            pair.car = readln(rawstr)
        }
    }
    
    func move(uid: UInt, toNextOfUid: UInt) {
        
    }
    
    ///// Export /////
    
    func str() -> String {
        var acc : String = ""
        
        for expr in trees {
            acc += expr.str(indent, level: 1) + "\n\n"
        }
        
        return acc
    }
    
    ///// Utilities /////
    
    private func delayed_list_of_values(_opds :SExpr) -> [SExpr] {
        if let atom = _opds as? Atom {
            return [atom]
        } else {
            return tail_delayed_list_of_values(_opds, acc: [])
        }
    }
    
    private func tail_delayed_list_of_values(_opds :SExpr, var acc: [SExpr]) -> [SExpr] {
        if let pair = _opds as? Pair {
            acc.append(pair.car)
            return tail_delayed_list_of_values(pair.cdr, acc: acc)
        } else {
            return acc
        }
    }
}

