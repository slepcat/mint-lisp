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
        
        return foldl(_func, acc, operands)
    }
}

func map<T, U>(_func: (T) -> U, var operands: [T]) -> [U] {
    return tail_map(_func, [], operands)
}

private func tail_map<T, U>(_func: (T) -> U, var acc: [U], var operands: [T]) -> [U] {
    if operands.count == 0 {
        return acc
    } else {
        let head = operands.removeAtIndex(0)
        acc.append(_func(head))
        return tail_map(_func,acc, operands)
    }
}

func flatMap<T, U>(var operands: [T],f: (T) -> [U]) -> [U] {
    let nestedList = tail_map(f, [], operands)
    return flatten(nestedList)
}

private func flatten<U>(nested:[[U]]) -> [U] {
    return tail_flatten(nested, [])
}

private func tail_flatten<U>(var nested:[[U]], acc:[U]) -> [U] {
    if nested.count == 0 {
        return acc
    } else {
        let head = nested.removeAtIndex(0)
        let newacc = head + acc
        return tail_flatten(nested, newacc)
    }
}

func _and(a :Bool, b: Bool) -> Bool {
    return (a && b)
}

func _or(a :Bool, b: Bool) -> Bool {
    return (a || b)
}
