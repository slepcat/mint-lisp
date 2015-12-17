//
//  mintlisp-test.swift
//  mint-lisp
//
//  Created by NemuNeko on 2015/09/06.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation
import Quick
import Nimble

class ParserSpec: QuickSpec {
    override func spec() {
        it("should parse raw string to tokens") {
            let rawstr = "(define (test-func a b) (+ a b))"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var nums_parsed = 0
            var nums_unparsed = 0
            
            if let parsedTokens = tokens.first {
                nums_parsed = parsedTokens.0.count
                nums_unparsed = parsedTokens.1.count
            }
            
            expect(nums_parsed).to(equal(13))
            expect(nums_unparsed).to(equal(0))
        }
        
        it("should parse tokens to S-expression") {
            let rawstr = "(define (test-func a b) (+ a b))"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            
            var debug_str = ""
            var nums_unparsed = 0
            
            if let parsedTokens = tokens.first {
                let parser = parseLispExpr()
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    debug_str = res.0._debug_string()
                    nums_unparsed = res.1.count
                }
            }
            
            expect(debug_str).to(equal("(define . ((Symbol:test-func . (Symbol:a . (Symbol:b . _null_))) . ((Symbol:+ . (Symbol:a . (Symbol:b . _null_))) . _null_)))"))
            expect(nums_unparsed).to(equal(0))
        }
    }
}

class LispSpec: QuickSpec {
    override func spec() {
        
        // set up evaluation process
        let parser = parseLispExpr()
        let test_eval = Evaluator()
        let gl_env = Env()
        
        gl_env.hash_table = global_environment()
        
        it("should 'define' variable") {
            let rawstr_var = "(define test_var 100)"
            
            let tokens = lispTokenizer([Character](rawstr_var.characters))
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = gl_env.hash_table["test_var"] {
                if let int_val = res as? MInt {
                    test_res = int_val.value
                }
            }
            
            expect(test_res).to(equal(100))
        }
        
        it("should 'define' procedure") {
            let rawstr_func = "(define (fact n acc) (if (= n 0) acc (fact (- n 1) (* acc n))))"
            
            let tokens = lispTokenizer([Character](rawstr_func.characters))
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = false
            
            if let res = gl_env.hash_table["fact"] {
                if let _ = res as? Procedure {
                    test_res = true
                }
            }
            
            expect(test_res).to(equal(true))
        }
        
        it("should 'set' variable") {
            let rawstr_var = "(set! test_var 10)"
            
            let tokens = lispTokenizer([Character](rawstr_var.characters))
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = gl_env.hash_table["test_var"] {
                if let int_val = res as? MInt {
                    test_res = int_val.value
                }
            }
            
            expect(test_res).to(equal(10))
        }
        
        it("should eval s-expression") {
            let rawstr = "(+ 10 (- 10 5) (* 1 5))"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var eval_res:SExpr = MNull()
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    eval_res = test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = eval_res as? MInt {
                test_res = res.value
            }
            
            expect(test_res).to(equal(20))
        }
        
        it("should 'quote' without eval") {
            let rawstr = "(car (quote (1 2 3)))"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var eval_res:SExpr = MNull()
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    eval_res = test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = eval_res as? MInt {
                test_res = res.value
            }
            
            expect(test_res).to(equal(1))
        }
        
        it("should process recursive function") {
            let rawstr = "(fact 10 1)"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var eval_res:SExpr = MNull()
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    eval_res = test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = eval_res as? MInt {
                test_res = res.value
            }
            
            expect(test_res).to(equal(3628800))
        }
        
        it("should eval 'lambda'") {
            let rawstr = "((lambda (a b) (* a b)) 4 1.5)"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var eval_res:SExpr = MNull()
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    eval_res = test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0.0
            
            if let res = eval_res as? MDouble {
                test_res = res.value
            }
            
            expect(test_res).to(equal(6.0))
        }
        
        it("should eval multi recursive function") {
            let rawstr = "(begin (define (bit n) (if (= n 0) 1 (+ (bit (- n 1)) (bit (- n 1))))) (bit 8))"
            
            let tokens = lispTokenizer([Character](rawstr.characters))
            var eval_res:SExpr = MNull()
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    eval_res = test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = 0
            
            if let res = eval_res as? MInt {
                test_res = res.value
            }
            
            expect(test_res).to(equal(256))
        }
    }
}

class InterpreterSpec : QuickSpec {
    override func spec() {
        
        let interpreter = Interpreter()
        
        it("should read from line") {
            
            let expr = interpreter.readln("(+ 10 (- 10 5) (* 1 5))")
            
            expect(expr._debug_string()).to(equal("(Symbol:+ . (Int:10 . ((Symbol:- . (Int:10 . (Int:5 . _null_))) . ((Symbol:* . (Int:1 . (Int:5 . _null_))) . _null_))))"))
        }
        
        it("should read from file") {
            let expr = interpreter.readfile("(define (bit n) (if (= n 0) 1 (+ (bit (- n 1)) (bit (- n 1)))))\n(bit 8)\n(bit 10)")
            
            let num = expr.count
            
            expect(num).to(equal(3))
            expect(expr[0]._debug_string()).to(equal("(define . ((Symbol:bit . (Symbol:n . _null_)) . ((if . ((Symbol:= . (Symbol:n . (Int:0 . _null_))) . (Int:1 . ((Symbol:+ . ((Symbol:bit . ((Symbol:- . (Symbol:n . (Int:1 . _null_))) . _null_)) . ((Symbol:bit . ((Symbol:- . (Symbol:n . (Int:1 . _null_))) . _null_)) . _null_))) . _null_)))) . _null_)))"))
            expect(expr[1]._debug_string()).to(equal("(Symbol:bit . (Int:8 . _null_))"))
            expect(expr[2]._debug_string()).to(equal("(Symbol:bit . (Int:10 . _null_))"))
        }
        /*
        it("should remove uid designated element in the middle of binary tree") {
            
            var rmuid1 :UInt = 0
            var rmuid2 :UInt = 0
            
            let test_exp1 = interpreter.readln("(+ 1 2 3)")
            let test_exp2 = interpreter.readln("(+ 1 (+ 1 1) 3)")
            
            if let pair = test_exp1 as? Pair, let pair2 = test_exp2 as? Pair {
                rmuid1 = pair.caddr.uid
                rmuid2 = pair2.caddr.uid
            }
            
            let res1 = interpreter.remove(rmuid1)
            let res2 = interpreter.remove(rmuid2)
            
            expect(res1._debug_string()).to(equal("Int:2"))
            expect(res2._debug_string()).to(equal("(Symbol:+ . (Int:1 . (Int:1 . _null_)))"))
            expect(test_exp1._debug_string()).to(equal("(Symbol:+ . (Int:1 . (Int:3 . _null_)))"))
            expect(test_exp2._debug_string()).to(equal("(Symbol:+ . (Int:1 . (Int:3 . _null_)))"))
        }
        
        it("should remove uid designated element without removing pairs which it contain") {
            var rmuid :UInt = 0
            var notrm :UInt = 0
            
            let test_exp = interpreter.readln("(+ (+ (* 3 2) 2) 3 2)")
            
            if let pair = test_exp as? Pair {
                rmuid = pair.cadr.uid
                print(pair.cadr._debug_string())
                if let pair2 = pair.cadr as? Pair {
                    notrm = pair2.cadr.uid
                    print(pair2.cadr._debug_string())
                }
            }
            
            let res = interpreter.remove(rmuid)
            let remain = interpreter.lookup(notrm)
            
            expect(test_exp._debug_string()).to(equal("(Symbol:+ . (Int:3 . (Int:2 . _null_)))"))
            expect(remain.target.isNull()).to(equal(false))
        }
        
        it("should remove designated uid s-expression in the last of binary tree") {
            
            var rmid:UInt = 0
            
            if let head = interpreter.trees[0] as? Pair {
                rmid = head.cadddr.uid
                print(head.cadddr._debug_string())
            }
            
            let str = interpreter.remove(rmid)._debug_string()
            expect(str).to(equal("(Symbol:* . (Int:1 . (Int:5 . _null_)))"))
            expect(interpreter.trees[0]._debug_string()).to(equal("(Symbol:+ . (Int:10 . ((Symbol:- . (Int:10 . (Int:5 . _null_))) . _null_)))"))

            //println(interpreter.str())
        }
        
        // add
        
        // overwrite
        
        it("should take one element and insert after another element") {
            var uid :UInt = 0
            var nextTo :UInt = 0
            
            let test_exp = interpreter.readln("(+ 1 2 3)")
            
            if let pair = test_exp as? Pair {
                uid = pair.cadddr.uid
                print(pair.cadddr._debug_string())
                nextTo = pair.cadr.uid
                print(pair.cadr._debug_string())
            }
            
            interpreter.insert(uid, toNextOfUid: nextTo)
            
            expect(test_exp._debug_string()).to(equal("(Symbol:+ . (Int:1 . (Int:3 . (Int:2 . _null_))))"))
        }
        */
    }
}
