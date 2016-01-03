//
//  Interpreter.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/31.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

public class Interpreter : NSObject {
    
    var threadPool : [NSThread] = []
    var executing : Bool = false
    
    var trees:[SExpr] = []
    let global: Env
    
    public var indent: String = "  "
    
    public override init() {
        global = Env()
        global.hash_table = global_environment()
    }
    
    public func init_env() {
        global.hash_table = global_environment()
    }
    
    //let evaluator = Evaluator()
    
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
        
        // return value of 'read()' is used as member of lisp binary tree. it must be unique.
        return MNull()
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
        
        return MNull.errNull
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
            //trees += result
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
    /*
    public func reload_env() {
        global.hash_table = global_environment()
        
        for tree in trees {
            if let pair = tree as? Pair {
                if let _ = pair.car as? MDefine {
                    eval(pair)
                }
            }
        }
    }*/
    
    public func lookup(uid: UInt) -> (conscell: SExpr, target: SExpr) {
        for exp in trees {
            let res = exp.lookup_exp(uid)
            if res.target.uid != MNull.errNull.uid {
                return res
            }
        }
        
        return (MNull.errNull, MNull.errNull)
    }
    
    ///// Look up location of uid /////
    
    public func lookup_treeindex_of(uid: UInt) -> Int? {
        for var i = 0; trees.count > i; i++ {
            let res = trees[i].lookup_exp(uid)
            
            if !res.target.isNull() {
                return i
            }
        }
        
        return nil
    }
    
    // run all trees
    
    func run_all() {
        
        cancell()
        
        init_env()
        
        var treearray : [SExpr] = []
        
        for tree in trees {
            treearray.append(tree.mirror_for_thread())
        }
        
        let task = Evaluator(exps: treearray, env: global, retTo: self)
        
        let thread = NSThread(target: task, selector: "main", object: nil)
        thread.stackSize = 8388608 // set 8 MB stack size
        
        threadPool.append(thread)
        
        for th in threadPool {
            th.start()
        }
        
        executing = true
    }
    
    
    // update run when 'trees' are edited.
    
    public func eval(uid: UInt) -> (SExpr, UInt) {
        
        cancell()
        
        // Boolean methods (originaly from openJSCAD) use deep recursion & require large call stack.
        //::::: Todo> Boolean without recursive call (may be with GCD concurrent iteration?), NSThread -> NSOperation
        if let i = lookup_treeindex_of(uid) {
            if let pair = trees[i] as? Pair {
                if let _ = pair.car as? MDefine {
                    let task = Evaluator(exp: trees[i].mirror_for_thread(), env: global, retTo: self)
                    
                    let thread = NSThread(target: task, selector: "main", object: nil)
                    thread.stackSize = 8388608 // set 8 MB stack size
                    
                    threadPool.append(thread)
                } else {
                    let task = Evaluator(exp: trees[i].mirror_for_thread(), env: global.clone(), retTo: self)
                    
                    let thread = NSThread(target: task, selector: "main", object: nil)
                    thread.stackSize = 8388608 // set 8 MB stack size
                    
                    threadPool.append(thread)
                }
            }
            //return (eval(trees[i]), trees[i].uid)
        }
        
        for th in threadPool {
            th.start()
        }
        
        executing = true
        
        return (MNull.errNull, 0)
    }
    
    // call back from NSThread when eval finished.
    func eval_result(result: AnyObject?) {
        
        print("eval finished", terminator: "\n")
        
        //controller.setNeedsDisplay()
        executing = false
    }
    
    
    public func eval_mainthread(uid: UInt) -> SExpr {
        let target = lookup(uid).target
        let task = Evaluator(exps: [target], env: global, retTo: self)
        
        task.main()
        
        if let result = task.res {
            return result
        } else {
            return MNull()
        }
    }
    /*
    public func eval(exp: SExpr) -> SExpr {
        return evaluator.eval(exp, gl_env: global)
    }
    */
    // stop all execution
    
    func cancell() {
        for th in threadPool {
            if th.executing {
                th.cancel()
            }
        }
        
        threadPool = []
        
        executing = false
    }
    
    ///// Export /////
    
    public func str() -> String {
        var acc : String = ""
        
        for expr in trees {
            acc += expr.str(indent, level: 1) + "\n\n"
        }
        
        return acc
    }
}

