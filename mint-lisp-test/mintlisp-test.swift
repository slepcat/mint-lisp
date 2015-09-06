//
//  mintlisp-test.swift
//  mint-lisp
//
//  Created by 安藤 泰造 on 2015/09/06.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation
import Quick
import Nimble

class ParserSpec: QuickSpec {
    override func spec() {
        it("should parse raw string to tokens") {
            let rawstr = "(define (test-func a b) (+ a b))"
            
            let tokens = lispTokenizer([Character](rawstr))
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
            
            let tokens = lispTokenizer([Character](rawstr))
            
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
            
            let tokens = lispTokenizer([Character](rawstr_var))
            
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
            
            let tokens = lispTokenizer([Character](rawstr_func))
            
            if let parsedTokens = tokens.first {
                let parsedExpr = parser(parsedTokens.0)
                
                if let res = parsedExpr.first {
                    test_eval.eval(res.0, gl_env: gl_env)
                }
            }
            
            var test_res = false
            
            if let res = gl_env.hash_table["fact"] {
                if let proc = res as? Procedure {
                    test_res = true
                }
            }
            
            expect(test_res).to(equal(true))
        }
        
        it("should 'set' variable") {
            let rawstr_var = "(set! test_var 10)"
            
            let tokens = lispTokenizer([Character](rawstr_var))
            
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
            
            let tokens = lispTokenizer([Character](rawstr))
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
            
            let tokens = lispTokenizer([Character](rawstr))
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
            
            let tokens = lispTokenizer([Character](rawstr))
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
            
            let tokens = lispTokenizer([Character](rawstr))
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
            
            let tokens = lispTokenizer([Character](rawstr))
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