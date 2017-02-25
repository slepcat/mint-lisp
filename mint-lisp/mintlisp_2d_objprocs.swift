//
//  mintlisp_2d_objprocs.swift
//  MINT
//
//  Created by NemuNeko on 2016/08/23.
//  Copyright © 2016年 Taizo A. All rights reserved.
//
//
//  basic 2d data objects are declared in 'mintlisp_lispobj'
//  constructor and accessor for these 2d data object. (read only)
//

import Foundation

class Shp : Primitive {
    override func apply(_ argsl: [SExpr]) -> SExpr {
        
        if argsl.count == 1 {
            if let p = argsl[0] as? MPath {
                return MShape(_value: Shape(path: p.value))
            }
        } else if argsl.count == 2 {
            if let p = argsl[0] as? MPath, let pl = argsl[1] as? MPlane {
                return MShape(_value: Shape(path: p.value, plane: pl.value))
            }
        } else if argsl.count > 2 {
            
            var acc : [LineSegment] = []
            
            for i in stride(from: 0, to: argsl.count - 1, by: 1) {
                if let ls = argsl[i] as? MLineSeg {
                    acc.append(ls.value)
                } else {
                    return MNull()
                }
            }
            
            if let last = argsl.last as? MLineSeg {
                acc.append(last.value)
                return MShape(_value: Shape(lines: acc))
            } else if let pl = argsl.last as? MPlane {
                return MShape(_value: Shape(lines: acc, plane: pl.value))
            }
        }
        
        print("shape take a path ,a path and plane, line-segments, or line-segments and plane")
        return MNull()
    }
}

