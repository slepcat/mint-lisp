//
//  mintlisp_util.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/08/01.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation


func foldl<T>(_func: (T, T) -> T, var acc: T, var operands: [T]) -> T{
    if operands.count == 0 {
        return acc
    } else {
        let head = operands.removeAtIndex(0)
        acc = _func(acc, head)
        
        return foldl(_func, acc: acc, operands: operands)
    }
}

func map<T, U>(_func: (T) -> U, operands: [T]) -> [U] {
    return tail_map(_func, acc: [], operands: operands)
}

private func tail_map<T, U>(_func: (T) -> U, var acc: [U], var operands: [T]) -> [U] {
    if operands.count == 0 {
        return acc
    } else {
        let head = operands.removeAtIndex(0)
        acc.append(_func(head))
        return tail_map(_func,acc: acc, operands: operands)
    }
}

func flatMap<T, U>(operands: [T],f: (T) -> [U]) -> [U] {
    let nestedList = tail_map(f, acc: [], operands: operands)
    return flatten(nestedList)
}

private func flatten<U>(nested:[[U]]) -> [U] {
    return tail_flatten(nested, acc: [])
}

private func tail_flatten<U>(var nested:[[U]], acc:[U]) -> [U] {
    if nested.count == 0 {
        return acc
    } else {
        let head = nested.removeAtIndex(0)
        let newacc = head + acc
        return tail_flatten(nested, acc: newacc)
    }
}

func _and(a :Bool, b: Bool) -> Bool {
    return (a && b)
}

func _or(a :Bool, b: Bool) -> Bool {
    return (a || b)
}

// unique id generator.
// UID factory: we can request a unique ID through UID.get.newID
// Singleton

class UID {
    private var count:UInt = 0
    private init(){}
    
    var newID: UInt {
        return count++
    }
    
    class var get: UID {
        struct Static{
            static let idFactory = UID()
        }
        return Static.idFactory
    }
}
