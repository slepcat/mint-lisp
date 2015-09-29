//
//  Interpreter.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/31.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

public class Interpreter {
    
    var trees:[SExpr] = []
    let global: Env
    
    public var indent: String = "  "
    
    public init() {
        global = Env()
        global.hash_table = global_environment()
    }
    
    let evaluator = Evaluator()
    
    ///// Interpreter /////
    
    public func read(rawstr: String) -> SExpr {
        
        let tokens = lispTokenizer([Character](rawstr.characters))
        
        if let token = tokens.first {
            
            if token.0.count == 1{
                let exp = token.0[0].expr
                return exp
            } else {
                print("parse failed")
            }
        }
        
        return MNull.staticNull
    }
    
    public func readln(rawstr: String) -> SExpr {
        
        let tokens = lispTokenizer([Character](rawstr.characters))
        let parser = parseLispExpr()
        
        if let token = tokens.first {
            
            /*
            if token.1.count > 0 {
                print(token.1)
                print("tokenize failed")
            }
            */
            if let result = parser(token.0).first {
                if result.1.count > 0 {
                    print("parse failed")
                }
                
                trees.append(result.0)
                return result.0
            }
        }
        
        return MNull.staticNull
    }
    
    public func readfile(fileContent: String) -> [SExpr] {
        
        let tokens = lispTokenizer([Character](fileContent.characters))
        let parser = parseLispExpr()
        
        if let token = tokens.first {
            /*
            if token.1.count > 0 {
                print("tokenize failed")
            }
            */
            let result = read_recursive(token.0, parser: parser, acc: [])
            trees += result
            return result
        }
        
        return []
    }
    
    private func read_recursive(tokens: [LispToken], parser: [LispToken] -> [(SExpr, [LispToken])], var acc:[SExpr]) -> [SExpr] {
        if tokens.count == 0 {
            return acc
        } else {
            
            if let res = parser(tokens).first {
                
                acc.append(res.0)
                return read_recursive(res.1, parser: parser, acc: acc)
            }
            
            return [MNull()]
        }
    }
    
    public func preprocess(uid: UInt) -> SExpr {
        
        // todo
        
        return lookup(uid).target
    }
    
    public func lookup(uid: UInt) -> (conscell: SExpr, target: SExpr) {
        for exp in trees {
            let res = exp.lookup_exp(uid)
            if !res.target.isNull() {
                return res
            }
        }
        
        return (MNull.staticNull, MNull.staticNull)
    }
    
    public func eval(uid: UInt) -> SExpr {
        return evaluator.eval(preprocess(uid), gl_env:global)
    }
    
    public func eval(exp: SExpr) -> SExpr {
        return evaluator.eval(exp, gl_env: global)
    }
    
    ///// Export /////
    
    public func str() -> String {
        var acc : String = ""
        
        for expr in trees {
            acc += expr.str(indent, level: 1) + "\n\n"
        }
        
        return acc
    }
    
    ///// Utilities /////
    
    func delayed_list_of_values(_opds :SExpr) -> [SExpr] {
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

