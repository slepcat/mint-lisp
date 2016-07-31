//
//  mintlisp_lispobj.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/03.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

public class SExpr {
    
    public let uid : UInt
    
    init() {
        uid = UID.get.newID
    }
    
    init(uid: UInt) {
        self.uid = uid
    }
    
    func mirror_for_thread() -> SExpr {
        return SExpr(uid: uid)
    }
    
    func clone() -> SExpr {
        return SExpr()
    }
    
    func lookup_exp(uid:UInt) -> (conscell: SExpr, target: SExpr) {
        if self.uid == uid {
            return (MNull.errNull, self)
        } else {
            return (MNull.errNull, MNull.errNull)
        }
    }
    
    func isNull() -> Bool { return false }
    
    func eval(env: Env) -> SExpr {
        return self
    }
    
    public func str(indent:String, level: Int) -> String {
        return ""
    }
    
    public func _debug_string() -> String {
        return "_null_"
    }
}

public class Pair:SExpr {
    var car:SExpr
    var cdr:SExpr
    
    override init() {
        car = MNull()
        cdr = MNull()
        super.init()
    }
    
    init(car _car:SExpr) {
        car = _car
        cdr = MNull()
        super.init()
    }
    
    init(cdr _cdr:SExpr) {
        car = MNull()
        cdr = _cdr
        super.init()
    }
    
    init(car _car:SExpr, cdr _cdr:SExpr) {
        car = _car
        cdr = _cdr
        super.init()
    }
    
    init(uid: UInt, car: SExpr, cdr: SExpr) {
        self.car = car
        self.cdr = cdr
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return Pair(uid: uid, car: car.mirror_for_thread(), cdr: cdr.mirror_for_thread())
    }
    
    override func clone() -> SExpr {
        return Pair(car: car.clone(), cdr: car.clone())
    }
    
    override func lookup_exp(uid:UInt) -> (conscell: SExpr, target: SExpr) {
        
        if self.uid == uid {
            return (MNull.errNull, self)
        } else  {
            let resa = car.lookup_exp(uid)
            if resa.target.uid != MNull.errNull.uid {
                if resa.conscell.isNull() { return (self, resa.target) }
                return resa
            }
            
            let resd = cdr.lookup_exp(uid)
            
            if resd.target.uid != MNull.errNull.uid {
                if resd.conscell.isNull() { return (self, resd.target) }
                return resd
            }
            
            return (MNull.errNull, MNull.errNull)
            
        }
    }
    
    public override func str(indent: String, level:Int) -> String {
        
        var leveledIndent : String = ""
        for _ in 0.stride(to: level, by: 1) {
            leveledIndent += indent
        }
        
        let res = str_list_of_exprs(self, indent: indent, level: level + 1 )
        
        var acc : String = ""
        
        for s in res {
            if s[s.startIndex] == "(" {
                if indent == "" {
                    acc += s
                } else {
                    acc += "\n" + leveledIndent + s
                }
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
    
    private func tail_str_list_of_exprs(_opds :SExpr, acc: [String], indent:String, level: Int) -> [String] {
        if let pair = _opds as? Pair {
            var acc2 = acc
            
            acc2.append(pair.car.str(indent, level: level))
            return tail_str_list_of_exprs(pair.cdr, acc: acc2, indent: indent, level: level)
        } else {
            return acc
        }
    }
    
    public override func _debug_string() -> String {
        return "(\(car._debug_string()) . \(cdr._debug_string()))"
    }
}

// Primitive Form Syntax

public class Form:SExpr {
    
    var category : String {
        get {return "special form"}
    }
    
    public func params_str() -> [String] {
        return []
    }
}

public class MDefine:Form {
    
    override func mirror_for_thread() -> SExpr {
        return MDefine(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MDefine()
    }
    
    override public func params_str() -> [String] {
        return ["symbol", "value"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "define"
    }
    
    public override func _debug_string() -> String {
        return "define"
    }
}

public class MQuote: Form {
    
    override func mirror_for_thread() -> SExpr {
        return MQuote(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MQuote()
    }
    
    override public func params_str() -> [String] {
        return ["value"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "quote"
    }
    
    public override func _debug_string() -> String {
        return "quote"
    }
}

public class MBegin:Form {
    
    override func mirror_for_thread() -> SExpr {
        return MBegin(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MBegin()
    }
    
    override public func params_str() -> [String] {
        return [".procs"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "begin"
    }
    
    public override func _debug_string() -> String {
        return "begin"
    }
}

public class Procedure:Form {
    
    public var params:SExpr
    var body:SExpr
    var initial_env:Env
    var rec_env: Env? = nil
    
    override var category : String {
        get {return "custom"}
    }
    
    init(_params: SExpr, body _body: SExpr, env _env: Env) {
        initial_env = _env
        params = _params
        body = _body
        
        super.init()
    }
    
    private init(uid: UInt, params: SExpr, body: SExpr, initial_env: Env, rec_env: Env?) {
        self.params = params
        self.body = body
        self.initial_env = initial_env
        self.rec_env = rec_env
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return Procedure(uid: uid, params: params.mirror_for_thread(), body: body.mirror_for_thread(), initial_env: initial_env.clone(), rec_env: rec_env?.clone())
    }
    
    override func clone() -> SExpr {
        return Procedure(_params: params, body: body, env: initial_env)
    }
    
    func apply(env: Env, seq: [SExpr]) -> (exp: SExpr, env: Env) {
        
        let _params = delayed_list_of_args(self.params)
        
        if let _env = rec_env {
            for i in 0.stride(to: _params.count, by: 1) {
                if let sym = _params[i] as? MSymbol {
                    if seq.count > i {
                        _env.set_variable(sym.key, val: seq[i])
                    } else {
                        print("syntax error: procedure. small params number")
                        return (MNull(), env)
                    }
                } else {
                    if !_params[i].isNull() || i != 0 {
                        print("syntax error: procedure. not symbol in params")
                        return (MNull(), env)
                    }
                }
            }
        } else {
            if let new_env = initial_env.extended_env(_params, values: seq) {
                rec_env = new_env
            } else {
                // not properly env generated.
                return (MNull(), env)
            }
        }
        
        return (body, rec_env!.clone())
    }
    
    override public func params_str() -> [String] {
        
        let _params = delayed_list_of_args(self.params)
        
        var acc : [String] = []
        
        for p in _params {
            acc += [p.str("", level: 0)]
        }
        return acc
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "<procedure>"
    }
    
    public override func _debug_string() -> String {
        return "procedure"
    }
}

// Macro object generated by def-syntax obj. CP of procedure
// (def-syntax <identifier> (<literal>...) ((<pattern> <template>)...))

public class Macro:Form {
    
    let identifier : SExpr
    let literals : [SExpr]
    let rules : [(pattern: SExpr, template: SExpr)]
    let env : Env
    
    override var category : String {
        get {return "custom"}
    }
    
    init(params: SExpr, env _env: Env) {
        env = _env
        
        let list = delayed_list_of_values(params)
        if list.count == 3 {
            identifier = list[0]
            literals = delayed_list_of_values(list[1])
            let rule_list = delayed_list_of_values(list[2])
            
            var acc : [(pattern: SExpr, template: SExpr)] = []
            
            for i in 0.stride(to: rule_list.count, by: 1) {
                let rule = delayed_list_of_values(list[i])
                if rule.count == 2 {
                    acc.append((pattern: rule[0], template: rule[1]))
                }
            }
            rules = acc
            
        } else {
            identifier = MNull()
            literals = []
            rules = []
        }
        
        super.init()
    }
    
    private init(uid: UInt, identifier _id: SExpr, literals _literals: [SExpr], rules _rules: [(pattern: SExpr, template: SExpr)], env _env: Env) {
        env = _env
        rules = _rules
        literals = _literals
        identifier = _id
        
        super.init(uid: uid)
    }
    
    private init(identifier _id: SExpr, literals _literals: [SExpr], rules _rules: [(pattern: SExpr, template: SExpr)], env _env: Env) {
        env = _env
        rules = _rules
        literals = _literals
        identifier = _id
        
        super.init()
    }
    
    public func expand(expr: SExpr) -> SExpr {
        
        //match expr with rules
        
        for (pattern, template) in rules {
            if let result = match(expr, pattern: pattern, template: template) {
                return result
            }
        }
        
        return MNull()
    }
    
    private func match(expr: SExpr, pattern: SExpr, template: SExpr) -> SExpr? {
        
        var result : [(key : MSymbol, expr : SExpr)] = []
        
        
        
        return nil
    }
    
    private func matcher(expr: SExpr, pattern: SExpr) -> [(MSymbol, SExpr)]? {
        if let matched_pair = expr as? Pair, let pt_pair = pattern as? Pair {
            
            if let res_car = matcher(matched_pair.car, pattern: pt_pair.car), let res_cdr = matcher(matched_pair.cdr, pattern: pt_pair.cdr) {
                return res_car + res_cdr
            }
            
        } else if let sym = pattern as? MSymbol {
            
            if isSubIdentifier(sym) {
                if let sym2 = expr as? MSymbol {
                    if sym2.key == sym.key {
                        return [(sym, sym2)]
                    }
                }
                
            } else if sym.key == "..." {
                
                return matchstar()
                
            }
            
        }
        
        return nil
    }
    
    private func matchstar() -> [(MSymbol, SExpr)]? {
        return nil
    }
    
    private func isSubIdentifier(expr : SExpr) -> Bool {
        for lt in literals {
            if let sym = lt as? MSymbol, let sym2 = expr as? MSymbol {
                if sym.key == sym2.key {
                    return true
                }
            }
        }
        
        return false
    }
    
    override func mirror_for_thread() -> SExpr {
        
        var newrules : [(pattern: SExpr, template: SExpr)] = []
        var newlit : [SExpr] = []
        
        for elm in rules {
            newrules.append((pattern: elm.pattern.mirror_for_thread(), template: elm.template.mirror_for_thread()))
        }
        
        for elm in literals {
            newlit.append(elm.mirror_for_thread())
        }
        
        return Macro(uid: uid, identifier: identifier.mirror_for_thread(),literals: newlit, rules: newrules, env: env.clone())
    }
    
    override func clone() -> SExpr {
        var newrules : [(pattern: SExpr, template: SExpr)] = []
        var newlit : [SExpr] = []
        
        for elm in rules {
            newrules.append((pattern: elm.pattern.clone(), template: elm.template.clone()))
        }
        
        for elm in literals {
            newlit.append(elm.clone())
        }
        
        return Macro(identifier: identifier.clone(),literals: newlit, rules: newrules, env: env.clone())
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "<syntax>"
    }
    
    public override func _debug_string() -> String {
        return "syntax"
    }
}

public class MLambda: Form {
    
    override func mirror_for_thread() -> SExpr {
        return MLambda(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MLambda()
    }
    
    func make_lambda(params: SExpr, body: SExpr) -> SExpr {
        return Pair(car: self, cdr: Pair(car: params, cdr: Pair(car: body)))
    }
    
    public override func params_str() -> [String] {
        return ["params", "body"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "lambda"
    }
    
    public override func _debug_string() -> String {
        return "lambda"
    }
}

public class MIf: Form {
    
    override func mirror_for_thread() -> SExpr {
        return MIf(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MIf()
    }
    
    public override func params_str() -> [String] {
        return ["predic", "then", "else"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "if"
    }
    
    public override func _debug_string() -> String {
        return "if"
    }
}

public class MSet:Form {
    
    override func mirror_for_thread() -> SExpr {
        return MSet(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MSet()
    }
    
    public override func params_str() -> [String] {
        return ["symbol", "value"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "set!"
    }
    
    public override func _debug_string() -> String {
        return "set!"
    }
}

public class Import:Form {
    override func mirror_for_thread() -> SExpr {
        return Import(uid: uid)
    }
    
    override func clone() -> SExpr {
        return Import()
    }
    
    public override func params_str() -> [String] {
        return ["libname"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "import"
    }
    
    public override func _debug_string() -> String {
        return "import"
    }
}

public class Export:Form {
    override func mirror_for_thread() -> SExpr {
        return Export(uid: uid)
    }
    
    override func clone() -> SExpr {
        return Export()
    }
    
    public override func params_str() -> [String] {
        return ["symbol, template"]
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "export"
    }
    
    public override func _debug_string() -> String {
        return "export"
    }
}

// Atoms
// Symbol and Literals

public class Atom:SExpr {
    
}

public class MSymbol:Atom {
    var key : String
    
    init(_key: String) {
        key = _key
        super.init()
    }
    
    private init(uid: UInt, key: String) {
        self.key = key
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MSymbol(uid: uid, key: key)
    }
    
    override func clone() -> SExpr {
        return MSymbol(_key: key)
    }
    
    override func eval(env: Env) -> SExpr {
        return env.lookup(key)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return key
    }
    
    public override func _debug_string() -> String {
        return "Symbol:" + key
    }
}

public class Literal:Atom {
    
    override func eval(env: Env) -> SExpr {
        return self
    }
}

public class MInt: Literal {
    var value:Int
    
    init(_value: Int) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Int) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MInt(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MInt(_value: value)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    public override func _debug_string() -> String {
        return "Int:\(value)"
    }
}

public class MDouble: Literal {
    var value:Double
    
    init(_value: Double) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Double) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MDouble(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MDouble(_value: value)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    public override func _debug_string() -> String {
        return "Double:\(value)"
    }
}

public class MStr: Literal {
    var value:String
    
    init(_value: String) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: String) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MStr(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MStr(_value: value)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "\"" + value + "\""
    }
    
    public override func _debug_string() -> String {
        return "String:\"\(value)\""
    }
}

public class MChar: Literal {
    var value:Character
    
    init(_value: Character) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Character) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MChar(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MChar(_value: value)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    public override func _debug_string() -> String {
        return "Char:\(value)"
    }
}

public class MNull:Literal {
    
    override func mirror_for_thread() -> SExpr {
        return MNull(uid: uid)
    }
    
    override func clone() -> SExpr {
        return MNull()
    }
    
    // avoid consume uid. do not use as a member of s-expression.
    // cause identification problem for SExpr manipulation
    class var errNull:MNull {
        struct Static {
            static let singletonNull = MNull()
        }
        return Static.singletonNull
    }
    
    override func isNull() -> Bool {
        return true
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "null"
    }
    
    public override func _debug_string() -> String {
        return "_null_"
    }
}

public class MBool:Literal {
    var value:Bool
    
    init(_value: Bool) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Bool) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MBool(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MBool(_value: value)
    }
    
    public override func str(indent: String, level:Int) -> String {
        return "\(value)"
    }
    
    public override func _debug_string() -> String {
        return "Bool:\(value)"
    }
}

public class MVector:Literal {
    var value:Vector
    
    init(_value: Vector) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Vector) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MVector(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MVector(_value: value)
    }
    
    public override func str(indent: String, level: Int) -> String {
        return "(vec \(value.x) \(value.y) \(value.z))"
    }
    
    public override func _debug_string() -> String {
        return "Vector: [\(value.x), \(value.y), \(value.z)]"
    }
}

public class MVertex:Literal {
    var value:Vertex
    
    init(_value: Vertex) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Vertex) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MVertex(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MVertex(_value: value)
    }
    
    public override func str(indent: String, level: Int) -> String {
        
        var color = "(color"
        for c in value.color {
            color += " \(c)"
        }
        color += ")"
        
        return "(vex (vec \(value.pos.x) \(value.pos.y) \(value.pos.z)) (vec \(value.normal.x) \(value.normal.y) \(value.normal.z)) " + color + ")"
    }
    
    public override func _debug_string() -> String {
        
        var color = "["
        for c in value.color {
            color += " \(c)"
        }
        color += "]"
        
        return "Vertex: [\(value.pos.x), \(value.pos.y), \(value.pos.z)] [\(value.normal.x), \(value.normal.y), \(value.normal.z)] " + color
    }
}

public class MColor : Literal {
    var value = [Float](count: 3 ,repeatedValue: 0.5)
    
    init(_value: [Float]) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: [Float]) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MColor(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MColor(_value: value)
    }
    
    public override func str(indent: String, level: Int) -> String {
        
        var color = "(color"
        for c in value {
            color += " \(c)"
        }
        color += ")"
        
        return color
    }
    
    
    public override func _debug_string() -> String {
        
        var color = "Color: ["
        for c in value {
            color += "\(c), "
        }
        
        var chr = color.characters
        chr.removeLast()
        chr.removeLast()
        color = String(chr)
        color += "]"
        
        return color
    }
}

public class MPlane : Literal {
    var value:Plane
    
    init(_value: Plane) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Plane) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MPlane(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MPlane(_value: value)
    }
    
    public override func str(indent: String, level: Int) -> String {
        
        return "(plane (vec \(value.normal.x) \(value.normal.y) \(value.normal.z)) \(value.w))"
    }
    
    
    public override func _debug_string() -> String {
        
        return "Plane: [\(value.normal.x), \(value.normal.y), \(value.normal.z)], \(value.w) "
    }
}

public class MPolygon : Literal {
    var value : Polygon
    
    init(_value: Polygon) {
        value = _value
        super.init()
    }
    
    private init(uid: UInt, value: Polygon) {
        self.value = value
        super.init(uid: uid)
    }
    
    override func mirror_for_thread() -> SExpr {
        return MPolygon(uid: uid, value: value)
    }
    
    override func clone() -> SExpr {
        return MPolygon(_value: value)
    }
    
    public override func str(indent: String, level: Int) -> String {
        
        var acc = "(polygon "
        
        for vex in value.vertices {
            let mvex = MVertex(_value: vex)
            acc += mvex.description + " "
        }
        
        let mpln = MPlane(_value: value.plane)
        acc += mpln.description + ")"
        
        return acc
    }
    
    public override func _debug_string() -> String {
        
        var acc = "Polygon: "
        
        for vex in value.vertices {
            acc += "[\(vex.pos.x), \(vex.pos.y), \(vex.pos.z)]" + " "
        }
        
        acc += "normal \(value.plane.normal.x) \(value.plane.normal.y) \(value.plane.normal.z) w \(value.plane.w)"
        
        return acc
    }
}

/*

public class MintIO {
    
}

public class SExprIO : MintIO {
    public var exp_list : [SExpr]
    
    init(exps: [SExpr]) {
        exp_list = exps
    }
}

public class IOMesh: MintIO {
    public var mesh: [Float]
    public var normal: [Float]
    public var color: [Float]
    public var alpha: [Float]
    public var drawtype : UInt
    
    init(mesh:[Double], normal:[Double], color:[Float], alpha:[Float]) {
        
        func d2farray(array: [Double]) -> [Float] {
            var acc : [Float] = []
            
            for e in array {
                acc.append(Float(e))
            }
            
            return acc
        }
        
        self.mesh = d2farray(mesh)
        self.normal = d2farray(normal)
        self.color = color
        
        if alpha.count < (mesh.count / 3) {
            
            var al : [Float] = alpha
            
            while al.count < (mesh.count / 3) {
                al.append(1.0)
            }
            
            self.alpha = al
            
        } else {
            self.alpha = alpha
        }
        
        self.drawtype = 0
    }
    
    public func str(indent: String, level: Int) -> String {
        return "<<#IOMesh> \(mesh), \(normal), \(color)>"
    }
    
    public func _debug_string() -> String {
        return "<<#IOMesh> \(mesh), \(normal), \(color)>"
    }
}

public class IOErr: MintIO {
    public var err : String
    public var uid_err : UInt
    
    init(err: String, uid: UInt) {
        self.err = err
        uid_err = uid
    }
    
    public func str(indent: String, level: Int) -> String {
        return "<<#IOErr> \(err), uid: \(uid_err)>"
    }
    
    public func _debug_string() -> String {
        return "<<#IOErr> \(err), uid: \(uid_err)>"
    }
}
 
 */

extension Literal : CustomStringConvertible {
    public var description: String {
        return self.str("", level: 0)
    }
}
