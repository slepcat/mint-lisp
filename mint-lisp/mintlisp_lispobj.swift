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
        return self
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
    
    override func _debug_string() -> String {
        return "(\(car._debug_string()) . \(cdr._debug_string()))"
    }
}

// Primitive Form Syntax

class Form:SExpr {
    
}

class MDefine:Form {
    
    override func _debug_string() -> String {
        return "define"
    }
}

class MQuote: Form {
    
    override func _debug_string() -> String {
        return "quote"
    }
}

class MBegin:Form {
    
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
    
    override func _debug_string() -> String {
        return "procedure"
    }
}

class MLambda: Form {
    
    func make_lambda(params: SExpr, body: SExpr) -> SExpr {
        return Pair(car: self, cdr: Pair(car: params, cdr: Pair(car: body)))
    }
    
    override func _debug_string() -> String {
        return "lambda"
    }
}

class MIf: Form {
    
    override func _debug_string() -> String {
        return "if"
    }
}

class MSet:Form {
    
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