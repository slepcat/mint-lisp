//
//  mintlisp_util.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/01.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation


func foldl<T>(_ _func: (T, T) -> T, acc: T, operands: [T]) -> T{
    if operands.count == 0 {
        return acc
    } else {
        var acc = acc
        var operands = operands
        
        let head = operands.remove(at: 0)
        acc = _func(acc, head)
        
        return foldl(_func, acc: acc, operands: operands)
    }
}

func map<T, U>(_ _func: (T) -> U, operands: [T]) -> [U] {
    return tail_map(_func, acc: [], operands: operands)
}

private func tail_map<T, U>(_ _func: (T) -> U, acc: [U], operands: [T]) -> [U] {
    if operands.count == 0 {
        return acc
    } else {
        var acc = acc
        var operands = operands
        
        let head = operands.remove(at: 0)
        acc.append(_func(head))
        return tail_map(_func,acc: acc, operands: operands)
    }
}

func flatMap<T, U>(_ operands: [T],f: (T) -> [U]) -> [U] {
    let nestedList = tail_map(f, acc: [], operands: operands)
    return flatten(nestedList)
}

private func flatten<U>(_ nested:[[U]]) -> [U] {
    return tail_flatten(nested, acc: [])
}

private func tail_flatten<U>(_ nested:[[U]], acc:[U]) -> [U] {
    if nested.count == 0 {
        return acc
    } else {
        var nested = nested
        
        let head = nested.remove(at: 0)
        let newacc = head + acc
        return tail_flatten(nested, acc: newacc)
    }
}

func _and(_ a :Bool, b: Bool) -> Bool {
    return (a && b)
}

func _or(_ a :Bool, b: Bool) -> Bool {
    return (a || b)
}

///// Utilities /////

public func delayed_list_of_args(_ _opds :SExpr) -> [SExpr] {
    return delayed_list_of_values(_opds)
}

public func delayed_list_of_values(_ _opds :SExpr) -> [SExpr] {
    if let atom = _opds as? Atom {
        return [atom]
    } else {
        return tail_delayed_list_of_values(_opds, acc: [])
    }
}

private func tail_delayed_list_of_values(_ _opds :SExpr, acc: [SExpr]) -> [SExpr] {
    if let pair = _opds as? Pair {
        return tail_delayed_list_of_values(pair.cdr, acc: acc + [pair.car])
    } else {
        return acc
    }
}

public func list_from_array(_ array: [SExpr]) -> SExpr {
    return tail_list_from_array(array, acc: MNull())
}

private func tail_list_from_array(_ array: [SExpr], acc: SExpr) -> SExpr {
    if array.count == 0 {
        return acc
    } else {
        var array = array
        var acc = acc
        
        let exp = array.removeLast()
        acc = Pair(car: exp, cdr: acc)
        return tail_list_from_array(array, acc: acc)
    }
}

public func tail(_ _seq: [SExpr]) -> [SExpr] {
    var seq = _seq
    
    if seq.count > 0 {
        seq.remove(at: 0)
        return seq
    } else {
        return []
    }
}

///// numeric //////

func cast2double(_ exp: SExpr) -> Double? {
    switch exp {
    case let num as MInt:
        return Double(num.value)
    case let num as MDouble:
        return num.value
    default:
        print("cast-doulbe take only number literal", terminator: "\n")
        return nil
    }
}

func d2farray(_ array: [Double]) -> [Float] {
    var acc : [Float] = []
    
    for e in array {
        acc.append(Float(e))
    }
    
    return acc
}

// unique id generator.
// UID factory: we can request a unique ID through UID.get.newID
// Singleton

class UID {
    private var count:UInt = 0
    private init(){}
    
    var newID: UInt {
        count += 1
        return count
    }
    
    class var get: UID {
        struct Static{
            static let idFactory = UID()
        }
        return Static.idFactory
    }
}
