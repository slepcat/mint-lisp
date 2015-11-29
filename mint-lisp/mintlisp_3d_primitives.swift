//
//  mintlisp_3d_primitives.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/09/13.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation


protocol MintPort:class {
    func write(data: MintIO, uid: UInt)
}

protocol MintReadPort:class {
    func read(path: String, uid: UInt) -> MintIO
}

class MintStdPort {
    private var currentport : MintPort? = nil
    private var stderrport : MintPort? = nil
    private init(){}
    
    var port: MintPort? {
        return currentport
    }
    
    var errport: MintPort? {
        return stderrport
    }
    
    func setPort(newPort:MintPort) {
        currentport = newPort
    }
    
    func setErrPort(newErrPort : MintPort ) {
        stderrport = newErrPort
    }
    
    func errprint(err:String, uid: UInt) {
        stderrport?.write(IOErr(err: err, uid: uid), uid: uid)
    }
    
    class var get: MintStdPort {
        struct Static{
            static let portFactory = MintStdPort()
        }
        return Static.portFactory
    }
}

class Display: Primitive {
    
    override func apply(args: [SExpr]) -> SExpr {
        
        var acc: [Double] = []
        var acc_normal: [Double] = []
        var acc_color: [Float] = []
        var acc_alpha: [Float] = []
        
        for arg in args {
            let polys = delayed_list_of_values(arg)
            
            for poly in polys {
                if let p = poly as? MPolygon {
                    let vertices = p.value.vertices
                    
                    if vertices.count == 3 {
                        for vertex in vertices {
                            acc += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                            acc_normal += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                            acc_color += vertex.color
                            acc_alpha += [vertex.alpha]
                        }
                    } else if vertices.count > 3 {
                        // if polygon is not triangle, split it to triangle polygons
                        
                        //if polygon.checkIfConvex() {
                        
                        let triangles = p.value.triangulationConvex()
                        
                        for tri in triangles {
                            for vertex in tri.vertices {
                                acc += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                                acc_normal += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                                acc_color += vertex.color
                                acc_alpha += [vertex.alpha]
                            }
                        }
                    }
                    
                } else {
                    print("display take only polygons", terminator: "\n")
                    return MNull()
                }
            }
        }
        
        if let port = MintStdPort.get.currentport {
            port.write(IOMesh(mesh: acc, normal: acc_normal, color: acc_color, alpha: acc_alpha), uid: uid)
        }
        
        return MNull()
    }
    
    override var category : String {
        get {return "3D Primitives"}
    }
    
    override func params_str() -> [String] {
        return ["poly."]
    }
    
    override func str(indent: String, level: Int) -> String {
        return "display"
    }
    
    override func _debug_string() -> String {
        return "display"
    }
    
    private func delayed_list_of_values(_opds :SExpr) -> [SExpr] {
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

class Cube: Primitive {
    
    override var category : String {
        get {return "3D Primitives"}
    }
    
    override func apply(args: [SExpr]) -> SExpr {
        
        if args.count == 4 {
            
            if let width = cast2double(args[0]), let height = cast2double(args[1]), let depth = cast2double(args[2]), let center =  args[3] as? MVector {
                
                let left = -width/2 + center.value.x
                let right = width/2 + center.value.x
                let front = depth/2 + center.value.y
                let back = -depth/2 + center.value.y
                let bottom = -height/2 + center.value.z
                let top = height/2 + center.value.z
                
                var vertices : [Vertex] = []
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))] //bottom
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))] // front
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))] //right
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))] // back
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))] //left
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))] // top
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                
                let poly = Pair()
                var pointer = poly
                
                for var i = 0; (i + 3) < vertices.count; i += 3 {
                    var pl = Polygon(vertices: [vertices[i], vertices[i + 1], vertices[i + 2]])
                    pl.generateNormal()
                    pointer.car = MPolygon(_value: pl)
                    pointer.cdr = Pair()
                    pointer = pointer.cdr as! Pair
                }
                
                let i = vertices.count
                
                pointer.car = MPolygon(_value: Polygon(vertices: [vertices[i - 3], vertices[i - 2], vertices[i - 1]]))
                
                return poly
            }
        }
        
        print("cube take 3 double and 1 vector", terminator: "\n")
        return MNull()
    }
    
    override func params_str() -> [String] {
        return ["width", "height", "depth", "center"]
    }
}