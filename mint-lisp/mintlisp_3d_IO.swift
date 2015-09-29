//
//  mintlisp_3d_IO.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/09/13.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation

class Display: Primitive {
    override func apply(args: [SExpr]) -> SExpr {
        
        var acc: [Double] = []
        var acc_normal: [Double] = []
        var acc_color: [Float] = []
        
        if args.count != 1 {
            print("display take 1 arg", terminator: "")
            return MNull()
        }
        
        let polys = delayed_list_of_values(args[0])
        
        for arg in polys {
            if let poly = arg as? MPolygon {
                let vertices = poly.value.vertices
                
                if vertices.count == 3 {
                    for vertex in vertices {
                        acc += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                        acc_normal += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                        acc_color += vertex.color
                    }
                } else if vertices.count > 3 {
                    // if polygon is not triangle, split it to triangle polygons
                    
                    //if polygon.checkIfConvex() {
                    
                    let triangles = poly.value.triangulationConvex()
                    
                    for tri in triangles {
                        for vertex in tri.vertices {
                            acc += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                            acc_normal += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                            acc_color += vertex.color
                        }
                    }
                    
                    //} else {
                    
                    //}
                }
                
            } else {
                print("display take only polygons", terminator: "")
                return MNull()
            }
        }
        
        return IOMesh(mesh: acc, normal: acc_normal, color: acc_color)
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