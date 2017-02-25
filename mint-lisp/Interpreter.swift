//
//  Interpreter.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/31.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

public class Interpreter : NSObject {
    
    var threadPool : [Thread] = []
    var executing : Bool = false
    
    var trees:[SExpr] = []
    var global: Env
    
    public var indent: String = "  "
    
    // to detect cycle import
    private var imported : [String] = []
    
    public override init() {
        global = Env()
        global.hash_table = global_environment()
    }
    
    public func init_env() {
        global.hash_table = global_environment()
    }
    
    //let evaluator = Evaluator()
    
    ///// Interpreter /////
    
    public func read(_ rawstr: String) -> SExpr {
        
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
    
    public func readln(_ rawstr: String) -> SExpr {
        
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
    
    private func read_recursive(_ tokens: [LispToken], parser: ([LispToken]) -> [(SExpr, [LispToken])], acc:[SExpr]) -> [SExpr] {
        
        var acc2 = acc
        
        if tokens.count == 0 {
            return acc2
        } else {
            
            if let res = parser(tokens).first {
                
                acc2.append(res.0)
                return read_recursive(res.1, parser: parser, acc: acc2)
            }
            
            return [MNull()]
        }
    }
    
    
    ///// Pre-Processor /////
    // import external lib & expand macro
    
    public func preprocess(_ uid: UInt) -> SExpr {
        
        if let i = lookup_treeindex_of(uid) {
            // import or macro expand
            
            return preprocess(trees[i])

        } else {
            return MNull()
        }
    }
    
    public func preprocess(_ expr : SExpr) -> SExpr {
        
        // init import path record
        
        imported = []
        
        // import or macro expand
        
        if let pair = expr as? Pair {
            
            if let _ = pair.car as? Import {
                // if current tree is import, load libs
                // and return null and escape evaluation
            
                import_lib(pair, preprefix: "", depth: 0)
                return MNull()
            
            } else if let _ = pair.car as? Export {
                // if expr is Export, return null and escape evaluation
                
                return MNull()
            } else {
                // macro expansion
                return rec_macro_expansion(pair)
            }
        } else {
            return expr
        }
    }
    
    
    public func preprocess_import(_ expr : SExpr, prefix: String, depth: UInt) -> SExpr {
        // import or macro expand
        
        if let pair = expr as? Pair {
            
            if let _ = pair.car as? Import {
                // if current tree is import, load libs
                // and return null and escape evaluation
                
                import_lib(pair, preprefix: prefix, depth: depth)
                return MNull()
                
            } else if let _ = pair.car as? Export {
                // if expr is Export, return null and escape evaluation
                if depth == 1 {
                    // if depth is >1, do not add pallete imported leaves
                    // todo : add export to tool pallete
                }
                
                return MNull()
            } else {
                // macro expansion
                return rec_macro_expansion(pair)
            }
        } else {
            return expr
        }
    }
    
    //// library import ////
    
    func import_lib(_ expr: SExpr, preprefix: String, depth: UInt){
        
        func add_prefix(_ prefix: String, target: [String], expr: SExpr) {
            
            if let sym = expr as? MSymbol {
                for key in target {
                    if key == sym.key {
                        sym.key = prefix + "." + sym.key
                    }
                }
            } else if let pair = expr as? Pair {
                add_prefix(prefix, target: target, expr: pair.car)
                add_prefix(prefix, target: target, expr: pair.cdr)
            } else if let proc = expr as? Procedure {
                add_prefix(prefix, target: target, expr: proc.body)
            }
        }
        
        
        let list = delayed_list_of_values(expr)
        if list.count == 3 {
            if let path = list[1] as? MSymbol, let prefix_expr = list[2] as? MSymbol {
                
                // check import loop
                for p in imported {
                    if path.key == p {
                        print("error: same lib is imported repeatedly.")
                        return
                    }
                }
                
                // if not repeatedly imported, add to the record
                imported.append(path.key)
                
                let port = MintStdPort.get.readport
                if let result = port?.read(path.key, uid: path.uid) {
                    
                    var acc : [SExpr] = []
                    let exp_list = delayed_list_of_values(result)
                    
                    // generate prefix
                    
                    var prefix : String
                    
                    if preprefix == "" {
                        prefix = prefix_expr.key
                    } else {
                        prefix = preprefix + "." + prefix_expr.key
                    }
                    
                    acc = exp_list.map() { [unowned self] expr in
                        return self.preprocess_import(expr, prefix: prefix, depth: depth + 1)
                    }
                    
                    // save current env hash table to check added key later
                    
                    var prev_env: [String : SExpr] = global.hash_table
                    
                    let task = Evaluator(exps: acc, env: global, retTo: self)
                    task.main()
                    
                    // extract added variables
                    
                    var addedvars : [String] = []
                    
                    for (varkey, _) in global.hash_table {
                        if prev_env[varkey] == nil {
                            addedvars.append(varkey)
                        }
                    }
                    
                    // add prefix to avoid name space collision.
                    for (varkey, expr) in global.hash_table {
                        if prev_env[varkey] == nil {
                            global.hash_table.removeValue(forKey: varkey)
                            global.hash_table[prefix + "." + varkey] = expr
                            add_prefix(prefix, target: addedvars, expr: expr)
                        }
                    }
                }
            }
        }
    }
    
    ////  macro expansion ////
    
    func is_macro(_ expr: SExpr) -> Bool {
        if let sym = expr as? MSymbol {
            if let _ = sym.eval(global) as? Macro {
                return true
            }
        }
        
        return false
    }
    
    func rec_macro_expansion(_ expr: Pair) -> SExpr {
        if let macro = expr.car.eval(global) as? Macro {
            if let expanded = macro.expand(expr.cdr) as? Pair {
                return rec_macro_expansion(expanded)
            } else {
                return macro.expand(expr.cdr)
            }
        } else if let pair_a = expr.car as? Pair, let pair_d = expr.cdr as? Pair{
            return Pair(uid: expr.uid, car: rec_macro_expansion(pair_a), cdr: rec_macro_expansion(pair_d))
        } else if let pair_a = expr.car as? Pair {
            return Pair(uid: expr.uid, car: rec_macro_expansion(pair_a), cdr: expr.cdr)
        } else if let pair_d = expr.cdr as? Pair {
            return Pair(uid: expr.uid, car: expr.car, cdr: rec_macro_expansion(pair_d))
        } else {
            return expr
        }
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
    
    public func lookup(_ uid: UInt) -> (conscell: SExpr, target: SExpr) {
        for exp in trees {
            let res = exp.lookup_exp(uid)
            if res.target.uid != MNull.errNull.uid {
                return res
            }
        }
        
        return (MNull.errNull, MNull.errNull)
    }
    
    ///// Look up location of uid /////
    
    public func lookup_treeindex_of(_ uid: UInt) -> Int? {
        for i in stride(from: 0, to: trees.count, by: 1) {
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
            treearray.append(preprocess(tree.mirror_for_thread()))
        }
        
        let task = Evaluator(exps: treearray, env: global, retTo: self)
        
        let thread = Thread(target: task, selector: #selector(Evaluator.main), object: nil)
        thread.stackSize = 8388608 // set 8 MB stack size
        
        threadPool.append(thread)
        
        for th in threadPool {
            th.start()
        }
        
        executing = true
    }
    
    
    // update run when 'trees' are edited.
    
    public func eval(_ uid: UInt) -> (SExpr, UInt) {
        
        cancell()
        
        // Boolean methods (originaly from openJSCAD) use deep recursion & require large call stack.
        //::::: Todo> Boolean without recursive call (may be with GCD concurrent iteration?), NSThread -> NSOperation
        if let i = lookup_treeindex_of(uid) {
            if let pair = trees[i] as? Pair {
                if let _ = pair.car as? MDefine {
                    let task = Evaluator(exp: preprocess(trees[i].mirror_for_thread()), env: global, retTo: self)
                    
                    let thread = Thread(target: task, selector: #selector(Evaluator.main), object: nil)
                    thread.stackSize = 8388608 // set 8 MB stack size
                    
                    threadPool.append(thread)
                } else {
                    let task = Evaluator(exp: preprocess(trees[i].mirror_for_thread()), env: global.clone(), retTo: self)
                    
                    let thread = Thread(target: task, selector: #selector(Evaluator.main), object: nil)
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
    
    
    public func eval_mainthread(_ uid: UInt) -> SExpr {
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
    public func eval(exp: SExpr) {
        return evaluator.eval(exp, gl_env: global)
    }
    */
    
    // stop all execution
    
    func cancell() {
        for th in threadPool {
            if th.isExecuting {
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

