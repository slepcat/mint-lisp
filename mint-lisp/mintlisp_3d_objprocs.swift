//
//  mintlisp_3d_objprocs.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/09/12.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//
//  basic 3d data objects are declared in 'mintlisp_lispobj'
//  constructor and accessor for these 3d data object. (read only)
//

import Foundation


///// 3D Data Obj Constructor /////

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
        
        print("color take 3 or 4 double values")
        return MNull()
    }
}

class Pln : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 2 {
            if let vec = args[0] as? MVector {
                if let w = args[1] as? MDouble {
                    
                    return MPlane(_value: Plane(normal: vec.value, w: w.value))
                    
                } else if let point = args[1] as? MVector {
                    
                    return MPlane(_value: Plane(normal: vec.value, point: point.value))
                    
                }
            }
        } else if args.count == 3 {
            if let vecx = args[0] as? MVector, let vecy = args[1] as? MVector, let vecz = args[2] as? MVector {
                
                return MPlane(_value: Plane(a: vecx.value, b: vecy.value, c: vecz.value))
                
            } else if let vecx = args[0] as? MVertex, let vecy = args[1] as? MVertex, let vecz = args[2] as? MVertex {
                
                return MPlane(_value: Plane(a: vecx.value, b: vecy.value, c: vecz.value))
                
            }
        }
        
        print("plane take 1 polygon, 1 vector & 1 double, 2 vector, 3 vector, or 3 vertex")
        return MNull()
    }
}

class Poly : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        
        if args.count < 3 {
            print("polygon take more than 3 vertices")
            return MNull()
        }
        
        var acc : [Vertex] = []
        
        for a in args {
            if let vex = a as? MVertex {
                acc.append(vex.value)
            } else {
                print("polygon take only vertex values")
                return MNull()
            }
        }
        
        return MPolygon(_value: Polygon(vertices: acc))
    }
}

///// 3D Data Obj Accessor /////

class Poly_VexAtIndex : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 2 {
            if let poly = args[0] as? MPolygon, let i = args[1] as? MInt {
                let vertices = poly.value.vertices
                
                if vertices.count > i.value {
                    return MVertex(_value: vertices[i.value])
                } else {
                    print("poly.vex-at-index: the index is out of range")
                    return MNull()
                }
            }
        }
        print("poly.vex-at-index take 1 polygon and 1 int")
        return MNull()
    }
}

class Poly_VexCount : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let poly = args[0] as? MPolygon {
                return MInt(_value: poly.value.vertices.count)
            }
        }
        
        print("poly.vex-count take 1 polygon")
        return MNull()
    }
}

class Pln_normal: Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let pln = args[0] as? MPlane {
                return MVector(_value: pln.value.normal)
            }
        }
        
        print("plane.normal take 1 vector")
        return MNull()
    }
}

class Vex_Pos : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vex = args[0] as? MVertex {
                return MVector(_value: vex.value.pos)
            }
        }
        
        print("vex.pos take 1 vertex")
        return MNull()
    }
}

class Vex_Normal : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vex = args[0] as? MVertex {
                return MVector(_value: vex.value.normal)
            }
        }
        
        print("vex.normal take 1 vertex")
        return MNull()
    }
}

class Vex_Color : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vex = args[0] as? MVertex {
                return MColor(_value: vex.value.color)
            }
        }
        
        print("vex.color take 1 vertex")
        return MNull()
    }
}

class Color_r : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let c = args[0] as? MColor {
                return MDouble(_value: Double(c.value[0]))
            }
        }
        
        print("color.r take 1 color")
        return MNull()
    }
}

class Color_g : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let c = args[0] as? MColor {
                return MDouble(_value: Double(c.value[1]))
            }
        }
        
        print("color.r take 1 color")
        return MNull()
    }
}

class Color_b : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let c = args[0] as? MColor {
                return MDouble(_value: Double(c.value[2]))
            }
        }
        
        print("color.r take 1 color")
        return MNull()
    }
}

class Color_a : Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let c = args[0] as? MColor {
                
                if c.value.count < 4 {
                    print("color don't have alpha value")
                    return MNull()
                }
                
                return MDouble(_value: Double(c.value[3]))
            }
        }
        
        print("color.r take 1 color")
        return MNull()
    }
}

class Vec_x: Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vec = args[0] as? MVector {
                return MDouble(_value: vec.value.x)
            }
        }
        
        print("vec.x take 1 vector")
        return MNull()
    }
}

class Vec_y: Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vec = args[0] as? MVector {
                return MDouble(_value: vec.value.y)
            }
        }
        
        print("vec.y take 1 vector")
        return MNull()
    }
}

class Vec_z: Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        if args.count == 1 {
            if let vec = args[0] as? MVector {
                return MDouble(_value: vec.value.z)
            }
        }
        
        print("vec.z take 1 vector")
        return MNull()
    }
}