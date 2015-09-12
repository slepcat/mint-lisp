//
//  mintlisp_primitive.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/07.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class Primitive:Form {
    
    func apply(var args: [SExpr]) -> SExpr {
        if args.count == 0 {
            return MNull()
        } else {
            let head = args.removeAtIndex(0)
            return foldl(proc, head, args)
        }
    }
    
    func proc(a: SExpr, b: SExpr) -> SExpr {
        return MNull()
    }
}

class Plus:Primitive {
    
    override func proc(a: SExpr, b: SExpr) -> SExpr {
        switch a {
        case let num as MInt:
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: Double(num.value) + num2.value)
            case let num2 as MInt:
                return MInt(_value: num.value + num2.value)
            default:
                return MNull()
            }
        case let num as MDouble:
            
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: num.value + num2.value)
            case let num2 as MInt:
                return MDouble(_value: num.value + Double(num2.value))
            default:
                return MNull()
            }
        case let str as MStr:
            switch b {
            case let str2 as MStr:
                return MStr(_value: str.value + str2.value)
            case let chr as MChar:
                return MStr(_value: str.value + String(chr.value))
            default:
                return MNull()
                
            }
        case let chr as MChar:
            switch b {
            case let str as MStr:
                return MStr(_value: String(chr.value) + str.value)
            case let chr2 as MChar:
                return MStr(_value: String(chr.value) + String(chr2.value))
            default:
                return MNull()
            }
        default:
            return MNull()
            
        }
    }
}

class Minus:Primitive {
    
    override func proc(a: SExpr, b: SExpr) -> SExpr {
        switch a {
        case let num as MInt:
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: Double(num.value) - num2.value)
            case let num2 as MInt:
                return MInt(_value: num.value - num2.value)
            default:
                return MNull()
            }
        case let num as MDouble:
            
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: num.value - num2.value)
            case let num2 as MInt:
                return MDouble(_value: num.value - Double(num2.value))
            default:
                return MNull()
            }
        default:
            return MNull()
            
        }
    }
}

class Multiply:Primitive {
    
    override func proc(a: SExpr, b: SExpr) -> SExpr {
        switch a {
        case let num as MInt:
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: Double(num.value) * num2.value)
            case let num2 as MInt:
                return MInt(_value: num.value * num2.value)
            default:
                return MNull()
            }
        case let num as MDouble:
            
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: num.value * num2.value)
            case let num2 as MInt:
                return MDouble(_value: num.value * Double(num2.value))
            default:
                return MNull()
            }
        default:
            return MNull()
            
        }
    }
}

class Divide:Primitive {
    
    override func proc(a: SExpr, b: SExpr) -> SExpr {
        switch a {
        case let num as MInt:
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: Double(num.value) / num2.value)
            case let num2 as MInt:
                return MDouble(_value: Double(num.value) / Double(num2.value))
            default:
                return MNull()
            }
        case let num as MDouble:
            
            switch b {
            case let num2 as MDouble:
                return MDouble(_value: num.value / num2.value)
            case let num2 as MInt:
                return MDouble(_value: num.value / Double(num2.value))
            default:
                return MNull()
            }
        default:
            return MNull()
            
        }
    }
}

class isEqual:Primitive {
    
    override func apply(var args: [SExpr]) -> SExpr {
        if args.count == 0 {
            return MNull()
        } else {
            let head = args.removeAtIndex(0)
            let result = foldl(proc, head, args)
            if let res = result as? MBool {
                return res
            } else if let res = result as? MNull {
                println("Cannot apply \"-\" to non-number objects.")
                return MNull()
            } else {
                return MBool(_value: true)
            }
        }
    }
    
    override func proc(a: SExpr, b: SExpr) -> SExpr {
        switch a {
        case let num as MInt:
            switch b {
            case let num2 as MDouble:
                return Double(num.value) == num2.value ? a : MBool(_value: false)
            case let num2 as MInt:
                return Double(num.value) == Double(num2.value) ? a : MBool(_value: false)
            default:
                return MNull()
            }
        case let num as MDouble:
            
            switch b {
            case let num2 as MDouble:
                return num.value == num2.value ? a : MBool(_value: false)
            case let num2 as MInt:
                return num.value == Double(num2.value) ? a : MBool(_value: false)
            default:
                return MNull()
            }
        default:
            return MNull()
            
        }
    }
}

class CastDouble : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        
        if args.count == 1 {
            switch args[0] {
            case let num as MInt:
                return MDouble(_value: Double(num.value))
            case let num as MDouble:
                return num
            default:
                println("cast-doulbe take only number literal")
                return MNull()
            }
        }
        println("cast-double take only 1 element")
        return MNull()
    }
}

///// 3D Primitives /////

class Vec : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 2 {
            if let arg1 = args[0] as? MDouble, let arg2 = args[1] as? MDouble {
                return MVector(_value: Vector(x: arg1.value, y: arg2.value))
            }
        } else if args.count == 3 {
            if let arg1 = args[0] as? MDouble, let arg2 = args[1] as? MDouble, let arg3 = args[2] as? MDouble {
                return MVector(_value: Vector(x: arg1.value, y: arg2.value, z: arg3.value))
            }
        }
        
        return MNull()
    }
}

class Vex : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vec = args[0] as? MVector {
                return MVertex(_value: Vertex(pos: vec.value))
            }
        } else if args.count == 3 {
            if let vec = args[0] as? MVector, let normal = args[1] as? MVector, let color = args[2] as? MColor {
                
                var vex = Vertex(pos: vec.value)
                vex.color = color.value
                vex.normal = normal.value
                
                return MVertex(_value: vex)
            }
        }
        
        return MNull()
    }
}

class Color : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 3 {
            if let r = args[0] as? MDouble, let g = args[1] as? MDouble, let b = args[2] as? MDouble {
                let color = [Float(r.value), Float(g.value), Float(b.value)]
                return MColor(_value: color)
            }
        } else if args.count == 4 {
            if let r = args[0] as? MDouble, let g = args[1] as? MDouble, let b = args[2] as? MDouble, let a = args[3] as? MDouble {
                let color = [Float(r.value), Float(g.value), Float(b.value), Float(a.value)]
                return MColor(_value: color)
            }
        }
        
        println("color take 3 or 4 double values")
        return MNull()
    }
}

///// conscell procedures /////

class Cons : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 2 {
            
            return Pair(car: args[0], cdr: args[1])
        }
        
        println("cons must take 2 element")
        return MNull()
    }
}

class Car : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.car
            } else {
                println("car take only Pair")
            }
        } else {
            println("car take only 1 argument")
        }
        return MNull()
    }
}

class Cdr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cdr
            } else {
                println("cdr take only Pair")
            }
        } else {
            println("cdr take only 1 argument")
        }
        return MNull()
    }
}

class Caar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.caar
            } else {
                println("caar take only Pair")
            }
        } else {
            println("caar take only 1 argument")
        }
        return MNull()
    }
}

class Cadr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cadr
            } else {
                println("cadr take only Pair")
            }
        } else {
            println("cadr take only 1 argument")
        }
        return MNull()
    }
}

class Cddr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cddr
            } else {
                println("cddr take only Pair")
            }
        } else {
            println("cddr take only 1 argument")
        }
        return MNull()
    }
}

class Cdar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cdar
            } else {
                println("cdar take only Pair")
            }
        } else {
            println("cdar take only 1 argument")
        }
        return MNull()
    }
}

class Caaar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.caaar
            } else {
                println("caaar take only Pair")
            }
        } else {
            println("caaar take only 1 argument")
        }
        return MNull()
    }
}

class Caadr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.caadr
            } else {
                println("caadr take only Pair")
            }
        } else {
            println("caadr take only 1 argument")
        }
        return MNull()
    }
}

class Caddr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.caddr
            } else {
                println("caddr take only Pair")
            }
        } else {
            println("caddr take only 1 argument")
        }
        return MNull()
    }
}

class Cdddr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cdddr
            } else {
                println("cdddr take only Pair")
            }
        } else {
            println("cdddr take only 1 argument")
        }
        return MNull()
    }
}

class Cdaar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cdaar
            } else {
                println("cdaar take only Pair")
            }
        } else {
            println("cdaar take only 1 argument")
        }
        return MNull()
    }
}

class Cadar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cadar
            } else {
                println("cadar take only Pair")
            }
        } else {
            println("cadar take only 1 argument")
        }
        return MNull()
    }
}

class Cdadr : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cdadr
            } else {
                println("cdadr take only Pair")
            }
        } else {
            println("cdadr take only 1 argument")
        }
        return MNull()
    }
}

class Cddar : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pair = args.first as? Pair {
                return pair.cddar
            } else {
                println("cddar take only Pair")
            }
        } else {
            println("cddar take only 1 argument")
        }
        return MNull()
    }
}

///// IO /////

class Print : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            println(args[0])
        } else {
            println("println take only 1 argument")
        }
        return MNull()
    }
}

class Quit : Primitive {
    // dummy, for real quit process, see main.swift
    override func apply(args: [SExpr]) -> SExpr {
        println("byby")
        return MNull()
    }
    
}