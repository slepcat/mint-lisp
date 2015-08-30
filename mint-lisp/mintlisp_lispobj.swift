//
//  mintlisp_lispobj.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/03.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class SExpr {
    
    func eval(env: Env) -> SExpr {
        return MNull()
    }
    
    func eval_sequence(var seq:[SExpr], env:Env) -> SExpr {
        if seq.count <= 1 {
            if let exp = seq.first {
                return exp.eval(env)
            } else {
                println("Unexpected index error")
                return MNull()
            }
        }else{
            let first_exp = seq.removeAtIndex(0)
            
            first_exp.eval(env)
            return eval_sequence(seq, env: env)
        }
    }
    
    func _debug_string() -> String {
        return "_null_"
    }
}

class Pair:SExpr {
    var car:SExpr
    var cdr:SExpr
    
    override init() {
        car = MNull()
        cdr = MNull()
    }
    
    init(car _car:SExpr) {
        car = _car
        cdr = MNull()
    }
    
    init(cdr _cdr:SExpr) {
        car = MNull()
        cdr = _cdr
    }
    
    init(car _car:SExpr, cdr _cdr:SExpr) {
        car = _car
        cdr = _cdr
    }
    
    override func eval(env: Env) -> SExpr {
        return self
    }
    
    override func _debug_string() -> String {
        return "(\(car._debug_string()) . \(cdr._debug_string()))"
    }
}

// Primitive Form Syntax

class Form:SExpr {
    
    override func eval(env: Env) -> SExpr {
        return self
    }
    
    /*
    func form_eval(env: Env, cdr: SExpr) -> SExpr {
        return MNull()
    }
    */
    
    func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        return (MNull(), env)
    }
    
    // Generate array of literals from SExpr binary tree for apply procedure
    func list_of_values(_opds :SExpr, env: Env) -> [SExpr] {
        if let atom = _opds as? Atom {
            return [atom]
        } else {
            return tail_list_of_values(_opds, env: env, acc: [])
        }
    }
    
    private func tail_list_of_values(_opds :SExpr, env: Env, var acc: [SExpr]) -> [SExpr] {
        if let pair = _opds as? Pair {
            acc.append(pair.car.eval(env))
            return tail_list_of_values(pair.cdr, env: env, acc: acc)
        } else {
            return acc
        }
    }
    
    // Generate array of atoms without evaluation for Evaluator.eval() method
    func delayed_list_of_args(_opds :SExpr) -> [SExpr] {
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
    
    // Generate array of symbols without evaluation for params of special forms
    func delayed_list_of_params(_opds :SExpr) -> [SExpr] {
        return []
    }

}

class MDefine:Form {
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (SExpr, Env) {
        // define take 2 params & no args
        if (params.count == 2) && (args.count == 0) {
            // standard use of define : (define x 5)
            if let symbol = params.first as? MSymbol, let value = params.last {
                
                if let pair = value as? Pair {
                    // define lambda : (define f (lambda ...))
                    if let lambda = pair.car as? MLambda {
                        let proc = lambda.form_eval(env, params: [pair.cadr, pair.caddr], args: []).exp
                        if !env.define_variable(symbol.key, val: proc) {
                            println("Used varialble identifier")
                            return (MNull(), env)
                        } else {
                            println("\(symbol.key) is binded to \(proc._debug_string())")
                            return (MNull(), env)
                        }
                    }
                }
                
                // define variable: (define x 1)
                if !env.define_variable(symbol.key, val: value.eval(env)) {
                    println("Used varialble identifier")
                    return (MNull(), env)
                } else {
                    println("\(symbol.key) is binded to \(value._debug_string())")
                    return (MNull(), env)
                }
            // sintax sugar of define lambda: (define (f x) (+ x x))
            } else if let pair = params.first as? Pair, let body = params.last as? Pair {
                let lambda = MLambda()
                
                if let symbol = pair.car as? MSymbol {
                    let _params = [pair.cdr] + [body]
                    let proc = lambda.form_eval(env, params: _params, args: []).exp
                    
                    if !env.define_variable(symbol.key, val: proc) {
                        println("Used varialble identifier")
                        return (MNull(), env)
                    } else {
                        println("\(symbol.key) is binded to \(body._debug_string())")
                        return (MNull(), env)
                    }
                }
            }
        }
        println("syntax error: define")
        return (MNull(), env)
    }
    
    // define do not evaluate it's args before apply
    override func delayed_list_of_args(_opds: SExpr) -> [SExpr] {
        return []
    }
    
    override func delayed_list_of_params(_opds: SExpr) -> [SExpr] {
        
        var params = tail_delayed_list_of_values(_opds, acc: [])
        return params
    }
    
    // return params for (define) special form
    
    override func _debug_string() -> String {
        return "define"
    }
}

class MQuote: Form {
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        
        if params.count == 1 {
            if let qhead = params.first as? Pair {
                return (qhead.car, env)
            } else if let qatom = params.first {
                return (qatom, env)
            }
        }
        println("syntax error: quote")
        return (MNull(), env)
    }
    
    override func delayed_list_of_args(_opds: SExpr) -> [SExpr] {
        return []
    }
    
    override func delayed_list_of_params(_opds: SExpr) -> [SExpr] {
        return [_opds]
    }
    
    override func _debug_string() -> String {
        return "quote"
    }
}

class MBegin:Form {
    
    /*
    override func form_eval(env: Env, cdr: SExpr) -> SExpr {
        return eval_sequence(delayed_list_of_args(cdr), env: env)
    }
    */
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        if let output = args.last {
            return (output, env)
        }
        println("syntax error: begin")
        return (MNull(), env)
    }
    
    override func _debug_string() -> String {
        return "begin"
    }
}

class Procedure:Form {
    
    var params:SExpr
    var body:SExpr
    var initial_env:Env
    var rec_env: Env? = nil
    
    init(_params: SExpr, body _body: SExpr, env _env: Env) {
        initial_env = _env
        params = _params
        body = _body
        
        super.init()
    }
    
    struct EnvPair {
        let parent:Env
        let child:Env
    }
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        
        let _params = delayed_list_of_args(self.params)
        
        if let _env = rec_env {
            for var i = 0; _params.count > i; i++ {
                if let sym = _params[i] as? MSymbol {
                    _env.set_variable(sym.key, val: args[i])
                } else {
                    println("syntax error: procedure. not symbol in params")
                    return (body, env)
                }
            }
        } else {
            if let new_env = initial_env.extended_env(_params, values: args) {
                rec_env = new_env.clone()
            } else {
                return (body, env)
            }
        }
        
        return (body, rec_env!.clone())
    }
    
    func apply(env: Env, seq: [SExpr]) -> (exp: SExpr, env: Env) {
        
        let _params = delayed_list_of_args(self.params)
        
        if let _env = rec_env {
            for var i = 0; _params.count > i; i++ {
                if let sym = _params[i] as? MSymbol {
                    _env.set_variable(sym.key, val: seq[i])
                } else {
                    println("syntax error: procedure. not symbol in params")
                    return (body, env)
                }
            }
        } else {
            if let new_env = initial_env.extended_env(_params, values: seq) {
                rec_env = new_env.clone()
            } else {
                return (body, env)
            }
        }
        
        return (body, rec_env!.clone())
    }
    
    override func _debug_string() -> String {
        return "procedure"
    }
}

class MLambda: Form {
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        if params.count == 2 {
            if let lambdaParam = params.first, let lambdaBody = params.last {
                return (Procedure(_params: lambdaParam, body: lambdaBody, env: env) , env)
            }
        }
        println("syntax error: lambda")
        return (MNull(), env)
    }
    
    func make_lambda(params: SExpr, body: SExpr) -> SExpr {
        return Pair(car: self, cdr: Pair(car: params, cdr: Pair(car: body)))
    }
    
    override func delayed_list_of_args(_opds: SExpr) -> [SExpr] {
        return []
    }
    
    override func delayed_list_of_params(_opds: SExpr) -> [SExpr] {
        
        var params = tail_delayed_list_of_values(_opds, acc: [])
        return params
    }

    override func _debug_string() -> String {
        return "lambda"
    }
}

class MIf: Form {
    /*
    override func form_eval(env: Env, cdr: SExpr) -> SExpr {
        if let exprs = cdr as? Pair {
            if let predicate = exprs.car.eval(env) as? MBool {
                if !predicate.value {
                    return exprs.caddr.eval(env)
                }
            }
            return exprs.cadr.eval(env)
        }
        println("syntax error: if")
        return MNull()
    }
    */
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        if (params.count == 2) && (args.count == 1) {
            if let predicate = args.first as? MBool, let t = params.first, let f = params.last {
                if !predicate.value {
                    return (f, env)
                }
                return (t, env)
            }
        }
        println("syntax error: if")
        return (MNull(), env)
    }
    
    override func delayed_list_of_args(_opds: SExpr) -> [SExpr] {
        if let pair = _opds as? Pair {
            return [pair.car]
        }
        
        println("syntax error: if, predicate")
        return [MNull()]
    }
    
    override func delayed_list_of_params(_opds: SExpr) -> [SExpr] {
        if let pair = _opds as? Pair {
            return [pair.cadr] + [pair.caddr]
        }
        
        println("syntax error: if, case")
        return [MNull()]
    }
    
    override func _debug_string() -> String {
        return "if"
    }
}

class MSet:Form {
    /*
    override func form_eval(env: Env, cdr: SExpr) -> SExpr {
        if let pair = cdr as? Pair {
            if let symbol = pair.car as? MSymbol, let valueCell = pair.cdr as? Pair {
                if !env.set_variable(symbol.key, val: valueCell.car) {
                    println("Undefined varialble identifier")
                }
            }
        }
        return MNull()
    }*/
    
    override func form_eval(env: Env, params: [SExpr], args: [SExpr]) -> (exp: SExpr, env: Env) {
        if (params.count == 1) && (args.count == 1) {
            if let symbol = params.first as? MSymbol, let arg = args.first {
                if !env.set_variable(symbol.key, val: arg) {
                    println("Undefined varialble identifier")
                }
            }
        }
        return (MNull(), env)
    }
    
    override func delayed_list_of_params(_opds: SExpr) -> [SExpr] {
        if let pair = _opds as? Pair {
            if let symbol = pair.car as? MSymbol {
                return [symbol]
            }
        }
        println("failed to escape")
        return [MNull()]
    }
    
    override func delayed_list_of_args(_opds: SExpr) -> [SExpr] {
        if let pair = _opds as? Pair {
            return [pair.cadr]
            
        }
        println("failed to escape")
        return [MNull()]
    }
    
    override func _debug_string() -> String {
        return "set!"
    }
}

// Atoms
// Symbol and Literals

class Atom:SExpr {
    
}

class MSymbol:Atom {
    var key : String
    
    init(_key: String) {
        key = _key
    }
    
    override func eval(env: Env) -> SExpr {
        return env.lookup(key)
    }
    
    override func _debug_string() -> String {
        return "Symbol:" + key
    }
}

class Literal:Atom {
    
    override func eval(env: Env) -> SExpr {
        return self
    }
}

class MInt: Literal {
    var value:Int
    
    init(_value: Int) {
        value = _value
    }
    
    override func _debug_string() -> String {
        return "Int:\(value)"
    }
}

class MDouble: Literal {
    var value:Double
    
    init(_value: Double) {
        value = _value
    }
    
    override func _debug_string() -> String {
        return "Double:\(value)"
    }
}

class MStr: Literal {
    var value:String
    
    init(_value: String) {
        value = _value
    }
    
    override func _debug_string() -> String {
        return "String:\"\(value)\""
    }
}

class MChar: Literal {
    var value:Character
    
    init(_value: Character) {
        value = _value
    }
    
    override func _debug_string() -> String {
        return "Char:\(value)"
    }
}

class MNull:Literal {
    
    override func eval(env: Env) -> SExpr {
        return self
    }
    
    override func _debug_string() -> String {
        return "_null_"
    }
}

class MBool:Literal {
    var value:Bool
    
    init(_value: Bool) {
        value = _value
    }
    
    override func eval(env: Env) -> SExpr {
        return self
    }
    
    
    override func _debug_string() -> String {
        return "Bool:\(value)"
    }
}

extension MStr : Printable {
    var description: String {
        return value
    }
}

extension MChar : Printable {
    var description: String {
        return String(value)
    }
}

extension MInt : Printable {
    var description: String {
        return "\(value)"
    }
}

extension MDouble : Printable {
    var description: String {
        return "\(value)"
    }
}

extension MBool : Printable {
    var description: String {
        return "\(value)"
    }
}

extension MNull : Printable {
    var description: String {
        return "null"
    }
}