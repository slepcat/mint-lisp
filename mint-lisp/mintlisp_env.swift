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
    
    /* debug print
    deinit {
        if hash_table.count > 10 {
            print("deinit env, with \(hash_table.count) elements")
        }
    }
    */
    
    
    func lookup(_ key : String) -> SExpr {
        if let value = hash_table[key] {
            return value
        } else {
            if let eenv = ext_env {
                return eenv.lookup(key)
            } else {
                print("Unbouded symbol", terminator: "\n")
                return MNull()
            }
        }
    }
    
    // todo: variable length of arguments
    func extended_env(_ symbols: [SExpr], values: [SExpr]) -> Env? {
        let _env = Env()
        _env.ext_env = self
        
        if symbols.count == values.count {
            for i in 0..<symbols.count {
                if let symbol = symbols[i] as? MSymbol {
                    _env.define_variable(symbol.key, val: values[i])
                } else {
                    print("Unproper parameter values", terminator: "\n")
                    return nil
                }
            }
            
            return _env
            
        } else if symbols.count == 1 {
            if let _ = symbols.last as? MNull {
                return _env
            }
        }
        
        print("Err. Number of Symbol and Value is unmatch.", terminator: "\n")
        return nil
    }
    
    func clone() -> Env {
        let cloned_env = Env()
        cloned_env.ext_env = self.ext_env?.clone()
        cloned_env.hash_table = self.hash_table
        return cloned_env
    }
    
    func define_variable(_ key: String, val: SExpr) -> Bool {
        if hash_table[key] == nil {
            hash_table[key] = val
            return true
        } else {
            return false
        }
    }
    
    func set_variable(_ key: String, val: SExpr) -> Bool {
        if hash_table[key] == nil {
            return false
        } else {
            hash_table[key] = val
            return true
        }
    }
    
    func define_variable_force(_ key: String, val: SExpr) -> Bool {
        hash_table[key] = val
        return true
    }
}

func global_environment() -> [String : SExpr] {
    var primitives = [String : SExpr]()
    
    ///// basic operators /////
    primitives["+"] = Plus()
    primitives["-"] = Minus()
    primitives["*"] = Multiply()
    primitives["/"] = Divide()
    primitives["="] = isEqual()
    primitives[">"] = GreaterThan()
    primitives["<"] = SmallerThan()
    primitives[">="] = EqualOrGreaterThan()
    primitives["<="] = EqualOrSmallerThan()
    primitives["mod"] = Mod()
    primitives["and"] = And()
    primitives["or"] = Or()
    primitives["not"] = Not()
    primitives["pow"] = Power()
    primitives["floor"] = Floor()
    primitives["ceil"] = Ceil()
    primitives["round"] = Round()
    primitives["cos"] = Cos()
    primitives["sin"] = Sin()
    primitives["tan"] = Tan()
    primitives["asin"] = ArcSin()
    primitives["acos"] = ArcCos()
    primitives["atan"] = ArcTan()
    primitives["atan2"] = ArcTan2()
    primitives["sinh"] = Sinh()
    primitives["cosh"] = Cosh()
    primitives["tanh"] = Tanh()
    primitives["abs"] = Abs()
    primitives["sqrt"] = Sqrt()
    primitives["exp"] = Exp()
    primitives["log"] = Log()
    primitives["log10"] = Log10()
    primitives["max"] = Max()
    primitives["min"] = Min()
    primitives["random"] = Random()
    primitives["time"] = Time()
    
    primitives["pi"] = MDouble(_value: M_1_PI)
    
    ///// conscell management /////
    
    primitives["cons"] = Cons()
    primitives["join"] = Join()
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
    
    ///// array managemetn /////
    
    primitives["array"] = NewArray()
    primitives["at-index"] = ArrayAtIndex()
    primitives["append"] = AppendArray()
    primitives["joint"] = JointArray()
    primitives["remove-at-index"] = RemoveAtIndex()
    primitives["remove-last"] = RemoveLast()
    primitives["remove-all"] = RemoveAll()
    primitives["count"] = CountArray()
    
    //primitives["list"] = isEqual()
    //primitives["apply"] = isEqual()
    //primitives["map"] = isEqual()
    
    ///// Type Casting /////
    
    primitives["cast-double"] = CastDouble()
    
    ///// 3D data objects /////
    
    primitives["vec"] = Vec()
    primitives["vec.x"] = Vec_x()
    primitives["vec.y"] = Vec_y()
    primitives["vec.z"] = Vec_z()

    primitives["vex"] = Vex()
    primitives["vex.pos"] = Vex_Pos()
    primitives["vex.normal"] = Vex_Normal()
    primitives["vex.color"] = Vex_Color()

    primitives["color"] = Color()
    primitives["color.r"] = Color_r()
    primitives["color.g"] = Color_g()
    primitives["color.b"] = Color_b()
    primitives["color.a"] = Color_a()
    
    primitives["plane"] = Pln()
    primitives["plane.normal"] = Pln_normal()
    
    primitives["ln"] = Ln()
    primitives["ln.pos"] = Ln_Pos()
    primitives["ln.dir"] = Ln_Dir()
    
    primitives["ln-seg"] = LnSeg()
    
    primitives["poly"] = Poly()
    primitives["poly.vex-at-index"] = Poly_VexAtIndex()
    primitives["poly.vex-count"] = Poly_VexCount()
    
    ///// 3d primitives /////
    
    primitives["cube"] = Cube()
    primitives["sphere"] = Sphere()
    primitives["cylinder"] = Cylinder()
    
    ///// 3d Transform /////
    
    primitives["set-color"] = SetColor()
    primitives["union"] = Union()
    primitives["subtract"] = Subtract()
    primitives["intersect"] = Intersect()
    primitives["rotate"] = Rotate()
    primitives["rotate-axis"] = RotateAxis()
    primitives["move"] = Translate()
    primitives["scale"] = Scale()
    
    ///// 2d data objects //////
    
    primitives["shape"] = Shp()
    
    ///// IO /////
    
    primitives["print"] = Print()
    //primitives["display"] = Display()
    primitives["quit"] = Quit()

    return primitives
}
