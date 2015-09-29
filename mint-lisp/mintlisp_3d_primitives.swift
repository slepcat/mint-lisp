//
//  mintlisp_3d_primitives.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/09/13.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class Cube: Primitive {

    override func apply(args: [SExpr]) -> SExpr {
        
        if args.count == 4 {
            
            if let width = args[0] as? MDouble, let height = args[1] as? MDouble, let depth = args[2] as? MDouble, let center =  args[3] as? MVector {
                
                let left = -width.value/2 + center.value.x
                let right = width.value/2 + center.value.x
                let front = -depth.value/2 + center.value.z
                let back = depth.value/2 + center.value.z
                let bottom = -height.value/2 + center.value.y
                let top = height.value/2 + center.value.y
                
                var vertices : [Vertex] = []
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))] //bottom
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))] // front
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))] //right
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: bottom))]
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))] // back
                vertices += [Vertex(pos: Vector(x: right, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))] //left
                vertices += [Vertex(pos: Vector(x: left, y: back, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: bottom))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))] // top
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: front, z: top))]
                vertices += [Vertex(pos: Vector(x: right, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: back, z: top))]
                vertices += [Vertex(pos: Vector(x: left, y: front, z: top))]
                
                var poly = Pair()
                var pointer = poly
                
                for var i = 0; (i + 3) < vertices.count; i += 3 {
                    pointer.car = MPolygon(_value: Polygon(vertices: [vertices[i], vertices[i + 1], vertices[i + 2]]))
                    pointer.cdr = Pair()
                    pointer = pointer.cdr as! Pair
                }
                
                let i = vertices.count
                
                pointer.car = MPolygon(_value: Polygon(vertices: [vertices[i - 3], vertices[i - 2], vertices[i - 1]]))
                
                return poly
            }
        }
        
        print("cube take 3 double and 1 vector")
        return MNull()
    }

}