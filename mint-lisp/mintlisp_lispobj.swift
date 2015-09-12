//
//  mintlisp_lispobj.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/03.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class SExpr {
    
    let uid : UInt
    
    init() {
        uid = UID.get.newID
    }
    
    func lookup_exp(uid:UInt) -> (conscell: SExpr, target: SExpr) {
        if self.uid == uid {
            return (MNull.staticNull, self)
        } else {
            return (MNull.staticNull, MNull.staticNull)
        }
    }
    
    func isNull() -> Bool { return false }
    
    func eval(env: Env) -> SExpr {
        return self
    }
    
    func str(indent:String, level: Int) -> String {
        return ""
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
    
    override func lookup_exp(uid:UInt) -> (conscell: SExpr, target: SExpr) {
        
        if self.uid == uid {
            return (MNull.staticNull, self)
        } else  {
            let resa = car.lookup_exp(uid)
            if !resa.target.isNull() {
                if resa.conscell.isNull() { return (self, resa.target) }
                return resa
            }
            
            let resd = cdr.lookup_exp(uid)
            
            if !resd.target.isNull() {
                if resd.conscell.isNull() { return (self, resd.target) }
                return resd
            }
            
            return (MNull.staticNull, MNull.staticNull)
            
        }
    }
    
    override func str(indent: String, level:Int) -> String {
        
        var leveledIndent : String = ""
        for var i = 0; level > i; i++ {
            leveledIndent += indent
        }
        
        let res = str_list_of_exprs(self, indent: indent, level: level + 1 )
        
        var acc : String = ""
        
        for s in res {
            if s[s.startIndex] == "(" {
                acc += "\n" + leveledIndent + s
            } else {
                if acc == "" {
                    acc += s
                } else {
                    acc += " " + s
                }
            }
        }
        
        return "(" + acc + ")"
    }
    
    private func str_list_of_exprs(_opds :SExpr, indent:String, level: Int) -> [String] {
        if let atom = _opds as? Atom {
            return [atom.str(indent, level: level)]
        } else {
            return tail_str_list_of_exprs(_opds, acc: [], indent: indent, level: level)
        }
    }
    
    private func tail_str_list_of_exprs(_opds :SExpr, var acc: [String], indent:String, level: Int) -> [String] {
        if let pair = _opds as? Pair {
            acc.append(pair.car.str(indent, level: level))
            return tail_str_list_of_exprs(pair.cdr, acc: acc, indent: indent, level: level)
        } else {
            return acc
        }
    }
    
    override func _debug_string() -> String {
        return "(\(car._debug_string()) . \(cdr._debug_string()))"
    }
}

// Primitive Form Syntax

class Form:SExpr {
    
}

class MDefine:Form {
    
    override func str(indent: String, level:Int) -> String {
        return "define"
    }
    
    override func _debug_string() -> String {
        return "define"
    }
}

class MQuote: Form {
    
    override func str(indent: String, level:Int) -> String {
        return "quote"
    }
    
    override func _debug_string() -> String {
        return "quote"
    }
}

class MBegin:Form {
    
    override func str(indent: String, level:Int) -> String {
        return "begin"
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
    
    override func str(indent: String, level:Int) -> String {
        return "proc: export error!"
    }
    
    override func _debug_string() -> String {
        return "procedure"
    }
}

class MLambda: Form {
    
    func make_lambda(params: SExpr, body: SExpr) -> SExpr {
        return Pair(car: self, cdr: Pair(car: params, cdr: Pair(car: body)))
    }
    
    override func str(indent: String, level:Int) -> String {
        return "lambda"
    }
    
    override func _debug_string() -> String {
        return "lambda"
    }
}

class MIf: Form {
    
    override func str(indent: String, level:Int) -> String {
        return "if"
    }
    
    override func _debug_string() -> String {
        return "if"
    }
}

class MSet:Form {
    
    override func str(indent: String, level:Int) -> String {
        return "set!"
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
    
    override func str(indent: String, level:Int) -> String {
        return key
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
    
    override func str(indent: String, level:Int) -> String {
        return "\(value)"
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
    
    override func str(indent: String, level:Int) -> String {
        return "\(value)"
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
    
    override func str(indent: String, level:Int) -> String {
        return value
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
    
    override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    override func _debug_string() -> String {
        return "Char:\(value)"
    }
}

class MNull:Literal {
    
    // avoid consume uid. do not use as a member of s-expression.
    // cause identification problem for SExpr manipulation
    class var staticNull:MNull {
        struct Static {
            static let singletonNull = MNull()
        }
        return Static.singletonNull
    }
    
    override func isNull() -> Bool {
        return true
    }
    
    override func str(indent: String, level:Int) -> String {
        return "null"
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
    
    override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    override func _debug_string() -> String {
        return "Bool:\(value)"
    }
}

class MVector:Literal {
    var value:Vector
    
    init(_value: Vector) {
        value = _value
    }
    
    override func str(indent: String, level: Int) -> String {
        return "(vec \(value.x) \(value.y) \(value.z))"
    }
    
    override func _debug_string() -> String {
        return "Vector: [\(value.x), \(value.y), \(value.z)]"
    }
}

class MVertex:Literal {
    var value:Vertex
    
    init(_value: Vertex) {
        value = _value
    }
    
    override func str(indent: String, level: Int) -> String {
        
        var color = "(color"
        for c in value.color {
            color += " \(c)"
        }
        color += ")"
        
        return "(vex (vec \(value.pos.x) \(value.pos.y) \(value.pos.z)) (vec \(value.normal.x) \(value.normal.y) \(value.normal.z))" + color + ")"
    }
    
    override func _debug_string() -> String {
        
        var color = "["
        for c in value.color {
            color += " \(c)"
        }
        color += "]"
        
        return "Vertex: [\(value.pos.x), \(value.pos.y), \(value.pos.z)] [\(value.normal.x), \(value.normal.y), \(value.normal.z)] " + color
    }
}

class MColor : Literal {
    var value = [Float](count: 3 ,repeatedValue: 0.5)
    
    init(_value: [Float]) {
        value = _value
    }
    
    override func str(indent: String, level: Int) -> String {
        
        var color = "(color"
        for c in value {
            color += " \(c)"
        }
        color += ")"
        
        return color
    }
    
    
    override func _debug_string() -> String {
        
        var color = "Color: ["
        for c in value {
            color += "\(c), "
        }
        
        var chr = [Character](color)
        chr.removeLast()
        chr.removeLast()
        color = String(chr)
        color += "]"
        
        return color
    }
}

class MPlane : Literal {
    var value:Plane
    
    init(_value: Plane) {
        value = _value
    }
    
    override func str(indent: String, level: Int) -> String {
        
        return "(plane (vec \(value.normal.x) \(value.normal.y) \(value.normal.z)) \(value.w))"
    }
    
    
    override func _debug_string() -> String {
        
        return "Plane: [\(value.normal.x), \(value.normal.y), \(value.normal.z)], \(value.w) "
    }
}

class MPolygon : Literal {
    var value : Polygon
    
    init(_value: Polygon) {
        value = _value
    }
    
    override func str(indent: String, level: Int) -> String {
        
        var acc = "(polygon "
        
        for vex in value.vertices {
            let mvex = MVertex(_value: vex)
            acc += mvex.description + " "
        }
        
        let mpln = MPlane(_value: value.plane)
        acc += mpln.description + ")"
        
        return acc
    }
    
    override func _debug_string() -> String {
        
        var acc = "Polygon: "
        
        for vex in value.vertices {
            acc += "[\(vex.pos.x), \(vex.pos.y), \(vex.pos.z)]" + " "
        }
        
        acc += "normal \(value.plane.normal.x) \(value.plane.normal.y) \(value.plane.normal.z) w \(value.plane.w)"
        
        return acc
    }
}

class IOMesh: Literal {
    var mesh: [Double]
    var normal: [Double]
    var color: [Float]
    
    init(mesh:[Double], normal:[Double], color:[Float]) {
        self.mesh = mesh
        self.normal = normal
        self.color = color
    }
    
    override func str(indent: String, level: Int) -> String {
        return "<<#IOMesh> \(mesh), \(normal), \(color)>"
    }
    
    override func _debug_string() -> String {
        return "<<#IOMesh> \(mesh), \(normal), \(color)>"
    }
}

extension Literal : Printable {
    var description: String {
        return self.str("", level: 0)
    }
}
