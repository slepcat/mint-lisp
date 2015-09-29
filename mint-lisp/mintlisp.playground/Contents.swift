//: Playground - noun: a place where people can play

import Foundation

enum LispToken {
    case LParentheses           //(
    case RParentheses           //)
    case Symbol(String)
    case Boolean(Bool)
    case LispStr(String)
    case LispChr(Character)
    case LispInt(Int)
    case LispDouble(Double)
    case VectorParentheses      //#(
    case Quote                  //’
    case BackQuate              //`
    case Comma                  //,
    case CommaAt                //,@
    case Dot                    //.
}

extension LispToken : CustomStringConvertible {
    var description: String {
        switch self {
        case .LParentheses:
            return "("
        case .RParentheses:
            return ")"
        case let .Symbol(str):
            return str
        case let .Boolean(_bool):
            if _bool {
                return "#t"
            } else {
                return "#f"
            }
        case let .LispStr(str):
            return str
        case let .LispChr(chr):
            return String(chr)
        case let .LispInt(num):
            return "\(num)"
        case let .LispDouble(num):
            return "\(num)"
        case .VectorParentheses:
            return "#("
        case .Quote:
            return "’"
        case .BackQuate:
            return "`"
        case .Comma:
            return ","
        case .CommaAt:
            return ",@"
        case .Dot:
            return "."
        }
    }
}

extension LispToken {
    var isLParentheses:Bool {
        switch self {
        case .LParentheses:
            return true
        default:
            return false
        }
    }
    
    var isRParentheses:Bool {
        switch self {
        case .RParentheses:
            return true
        default:
            return false
        }
    }
    
    var expr:SExpr {
        switch self {
        case .LParentheses:
            return Pair()
        case .RParentheses:
            return MNull()
        case let .LispInt(num):
            return MInt(_value: num)
        case let .LispDouble(num):
            return MDouble(_value: num)
        case let .LispStr(str):
            return MStr(_value: str)
        case let .LispChr(chr):
            return MChar(_value: chr)
        case let .Symbol(symbol):
            switch symbol {
            default:
                return MSymbol(_key: symbol)
            }
        case let .Boolean(bool):
            return MBool(_value: bool)
        default:
            print("Unsupported token type: \(self)")
            return MNull()
        }
    }
}

class SExpr {
    
    func isPair() -> Bool { return false }
    
    func isAtom() -> Bool { return false }
    
    /*
    func eval(env: Env) -> SExpr {
        return MNull()
    }
    
    func eval_sequence(var seq:[SExpr], env:Env) -> SExpr {
        if seq.count <= 1 {
            if let exp = seq.first {
                return exp.eval(env)
            } else {
                println("Unexpected index error")
                return MNull()
            }
        }else{
            let first_exp = seq.removeAtIndex(0)
            
            first_exp.eval(env)
            return eval_sequence(seq, env: env)
        }
    }*/
}

class Pair:SExpr {
    var car:SExpr
    var cdr:SExpr
    
    override init() {
        car = MNull()
        cdr = MNull()
    }
    
    init(car _car:SExpr) {
        car = _car
        cdr = MNull()
    }
    
    init(cdr _cdr:SExpr) {
        car = MNull()
        cdr = _cdr
    }
    
    init(car _car:SExpr, cdr _cdr:SExpr) {
        car = _car
        cdr = _cdr
    }
    /*
    override func eval(env: Env) -> SExpr {
        if let proc = car.eval(env) as? Procedure {
            let args = list_of_values(cdr, env: env)
            
            return proc.apply(args)
            
        } else {
            println("Not a procedure.")
            return MNull()
        }
    }
    
    private func list_of_values(_opds :SExpr, env: Env) -> [SExpr] {
        return []
    }
    */
    override func isPair() -> Bool { return true }
    
    func isDefine() -> Bool { return false }
    
    func isQuote() -> Bool { return false }
    
    func isProcedure() -> Bool { return false }
    
    func isLambda() -> Bool { return false }
    
    func isIf() -> Bool { return false }
    
    func isSet() -> Bool { return false }
}

// Primitive Form Syntax

class Define:Pair {
    override func isDefine() -> Bool { return true }
}

class Quote: Pair {
    override func isQuote() -> Bool { return true }
}

class Procedure:Pair {
    
    var params:SExpr { get { return car } set(value) {car = value}}
    var body:SExpr { get { return cdr} set(value) {cdr = value}}
    //var env: Env
    
    init(_params: SExpr, body _body: SExpr/*, env _env: Env*/) {
        //self.env = _env
        
        super.init()
        
        params = _params
        body = _body
    }
    
    override func isProcedure() -> Bool { return true }
    
    /*
    func apply(args: [SExpr]) -> SExpr {
        
        //let newenv = env.extended_env(list_of_values(params, env: env), values: args)
        
        return eval_sequence(args, env: newenv)
    }*/
}

class Lambda: Pair {
    override func isLambda() -> Bool { return true }
}

class If: Pair {
    override func isIf() -> Bool { return true }
}

class Set:Pair {
    override func isSet() -> Bool { return true }
}



class Atom:SExpr {
    
    override func isAtom() -> Bool { return true }
    
    func isLiteral() -> Bool { return false }
    
    func isSymbol() -> Bool { return false }
}

class MSymbol:Atom {
    var key : String
    
    init(_key: String) {
        key = _key
    }
    
    override func isSymbol() -> Bool {
        return true
    }
    /*
    override func eval(env: Env) -> SExpr {
        return env.lookup(key)
    }*/
}

class Literal:Atom {
    func isInt() -> Bool { return false }
    
    func isDouble() -> Bool { return false }
    
    func isStr() -> Bool { return false }
    
    func isChar() -> Bool { return false }
    
    func isBool() -> Bool { return false }
    
    func isNull() -> Bool { return false }
    
    override func isLiteral() -> Bool { return true }
    /*
    override func eval(env: Env) -> SExpr {
        return self
    }*/
}

class MInt: Literal {
    var value:Int
    
    init(_value: Int) {
        value = _value
    }
}

class MDouble: Literal {
    var value:Double
    
    init(_value: Double) {
        value = _value
    }
}

class MStr: Literal {
    var value:String
    
    init(_value: String) {
        value = _value
    }
}

class MChar: Literal {
    var value:Character
    
    init(_value: Character) {
        value = _value
    }
}

class MNull:Literal {
    /*
    override func eval(env: Env) -> SExpr {
        return self
    }*/
}

class MBool:Literal {
    var value:Bool
    
    init(_value: Bool) {
        value = _value
    }
    
    func unwrap() -> Bool {
        return value
    }
    /*
    override func eval(env: Env) -> SExpr {
        return self
    }*/
}

typealias SingleTokenizer = Comb<Character, LispToken>.Parser

struct Comb<Token, Result> {
    typealias Parser = [Token] -> [(Result, [Token])]
}

func pure<Token, Result>(result: Result) -> Comb<Token, Result>.Parser {
    return { input in return [(result, input)] }
}

func zero<Token, Result>() -> Comb<Token, Result>.Parser {
    return { input in return [] }
}

func consumer<Token>() -> Comb<Token, Token>.Parser {
    return { (var input:[Token]) in
        if input.count == 0 {
            return []
        } else {
            let head = input.removeAtIndex(0)
            return [(head, input)]
        }
    }
}

func unconsume<Token>() -> Comb<Token, Token>.Parser {
    return { (input:[Token]) in
        if let head = input.first {
            return [(head, input)]
        }
        return []
    }
}

func bind<Token, T, U>(parser: Comb<Token, T>.Parser, factory: T -> Comb<Token, U>.Parser) -> Comb<Token, U>.Parser {
    return { input in
        let res = parser(input)
        return flatMap(res) {(result, tail) in
            let parser = factory(result)
            return parser(tail)
        }
    }
}

func flatMap<T, U>(var operands: [T],f: (T) -> [U]) -> [U] {
    let nestedList = tail_map(f, acc: [], operands: operands)
    return flatten(nestedList)
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

func satisfy<Token>(condition: Token -> Bool) -> Comb<Token, Token>.Parser {
    return bind(consumer()) { r in
        if condition(r) {
            return pure(r)
        }
        return zero()
    }
}

func predict<Token>(condition: Token -> Bool) -> Comb<Token, Token>.Parser {
    return bind(unconsume()) { r in
        if condition(r) {
            return pure(r)
        }
        return zero()
    }
}

func token<Token :Equatable>(t: Token) -> Comb<Token, Token>.Parser {
    return satisfy { $0 == t }
}

func nextToken<Token :Equatable>(t: Token) -> Comb<Token, Token>.Parser {
    return predict { $0 == t }
}

func notToken<Token :Equatable>(t :Token) -> Comb<Token, Token>.Parser {
    return satisfy { $0 != t }
}

func oneOrMore<Token, Result>(parser: Comb<Token, Result>.Parser) -> Comb<Token, [Result]>.Parser {
    return oneOrMore(parser, buffer: [])
}

func zeroOrMore<Token, Result>(parser: Comb<Token, Result>.Parser) -> Comb<Token, [Result]>.Parser {
    return oneOrMore(parser) <|> pure([])
}

func zeroOrOne<Token, Result>(parser: Comb<Token, Result>.Parser) -> Comb<Token, [Result]>.Parser {
    return bind(parser) { r in return pure([r]) } <|> pure([])
}

private func oneOrMore<Token, Result>(parser: Comb<Token, Result>.Parser, buffer: [Result]) -> Comb<Token, [Result]>.Parser {
    return bind(parser) { r in
        let combine = buffer + [r]
        return oneOrMore(parser, buffer: combine) <|> pure(combine)
    }
}

infix operator <|> { associativity left precedence 130 }
func <|> <Token, Result>(lhs: Comb<Token, Result>.Parser, rhs: Comb<Token, Result>.Parser) -> Comb<Token, Result>.Parser {
    return { input in lhs(input) + rhs(input) }
}

infix operator <&> { associativity left precedence 130 }
func <&> <Token, Result>(lhs: Comb<Token, Result>.Parser, rhs: Comb<Token, Result>.Parser) -> Comb<Token, Result>.Parser {
    return { input in
        let lres = lhs(input)
        let rres = rhs(input)
        if (lres.count != 0) && (rres.count != 0) {
            return lres + rres
        }
        return []
    }
}

func ignoreWhitespace<T>(parser :Comb<Character, T>.Parser) -> Comb<Character, T>.Parser {
    return bind(zeroOrMore(NSCharacterSet.whitespaceAndNewlineCharacterSet().parser)) { result in
        return parser
    }
}

extension NSCharacterSet {
    var parser: Comb<Character, Character>.Parser {
        return satisfy { token in
            let unichar = (String(token) as NSString).characterAtIndex(0)
            return self.characterIsMember(unichar)
        }
    }
    
    var parserNot: Comb<Character, Character>.Parser {
        return satisfy { token in
            let unichar = (String(token) as NSString).characterAtIndex(0)
            return !self.characterIsMember(unichar)
        }
    }
    
    var parserPredict: Comb<Character, Character>.Parser {
        return predict { token in
            let unichar = (String(token) as NSString).characterAtIndex(0)
            return self.characterIsMember(unichar)
        }
    }
}

// basic regex

let alphabet : Comb<Character, Character>.Parser = bind(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").parser) { r in
    return pure(r)
}

let escapedDQuote : Comb<Character, Character>.Parser = bind(token(Character("\\"))) { _ in
    bind(token(Character("\""))) { r in
        return pure(r)
    }
}

let escapedEscape : Comb<Character, Character>.Parser = bind(token(Character("\\"))) { _ in
    bind(token(Character("\\"))) { r in
        return pure(r)
    }
}

let notEscapeOrDQuote : Comb<Character, Character>.Parser = satisfy({($0 != Character("\"")) && ($0 != Character("\\"))})

let number : Comb<Character, Character>.Parser = bind(NSCharacterSet(charactersInString: "0123456789").parser) { r in
    return pure(r)
}

let specialInitialLetter : Comb<Character, Character>.Parser = bind(NSCharacterSet(charactersInString: "!$%&*/:<=>?^_~").parser) { r in
    return pure(r)
}

let specialFollowingLetter : Comb<Character, Character>.Parser = bind(NSCharacterSet(charactersInString: "+-.@").parser) { r in
    return pure(r)
}

let numberSign : Comb<Character, Character>.Parser = bind(NSCharacterSet(charactersInString: "+-").parser) { r in
    return pure(r)
}

let floatDot : Comb<Character, Character>.Parser = bind(token(".")) { r in
    return pure(r)
}

let divider : Comb<Character, Character>.Parser = NSCharacterSet.whitespaceAndNewlineCharacterSet().parserPredict <|> nextToken("(") <|> nextToken(")") <|> nextToken("\"") <|>  nextToken(";")

// Tokens

let tokenLParentheses : SingleTokenizer = bind(token("(")) { _ in
    return pure(LispToken.LParentheses)
}

let tokenRParentheses : SingleTokenizer = bind(token(")")) { _ in
    return pure(LispToken.RParentheses)
}

let trueBoolean : SingleTokenizer = bind(token("#")) { x in
    bind(token("t")) { _ in
        bind(divider) { _ in
            return pure(LispToken.Boolean(true))
        }
    }
}

let falseBoolean : SingleTokenizer = bind(token("#")) { x in
    bind(token("f")) { _ in
        bind(divider) { _ in
            return pure(LispToken.Boolean(false))
        }
    }
}

let tokenBool : SingleTokenizer = trueBoolean <|> falseBoolean

let tokenInt : SingleTokenizer = bind(zeroOrOne(numberSign)) { (x : [Character]) in
    bind(oneOrMore(number)) { (r : [Character]) in
        bind(divider) { (_: Character) in
            return pure(LispToken.LispInt(Int(NSString(string: String(x + r)).intValue)))
        }
    }
}

let tokenDouble : SingleTokenizer = bind(numberSign <|> number) { (x:Character) in
    bind(zeroOrMore(number)) { (y:[Character]) in
        bind(token(".")) { (z:Character) in
            bind(oneOrMore(number)) { (a:[Character]) in
                bind(divider) { _ in
                    let num = [x] + y + [z] + a
                    return pure(LispToken.LispDouble(Double(NSString(string: String(num)).doubleValue)))
                }
            }
        }
    }
}

let tokenString : SingleTokenizer = bind(token(Character("\""))) { _ in
    bind(zeroOrMore(notEscapeOrDQuote <|> escapedDQuote <|> escapedEscape )) { (r:[Character]) in
        bind(token(Character("\""))) { _ in
            return pure(LispToken.LispStr(String(r)))
        }
    }
}

let tokenChar : SingleTokenizer = bind(token("#")) { _ in
    bind(token(Character("\\"))) { _ in
        bind(NSCharacterSet.whitespaceAndNewlineCharacterSet().parserNot) { r in
            bind(divider) { _ in
                return pure(LispToken.LispChr(r))
            }
        }
    }
}

let identifier : SingleTokenizer = bind(alphabet <|> specialInitialLetter) { (a:Character) in
    bind(zeroOrMore(alphabet <|> number <|> specialInitialLetter <|> specialFollowingLetter)) { (b:[Character]) in
        bind(divider) { (_:Character) in
            return pure(LispToken.Symbol(String([a] + b)))
        }
    }
}

let uniqueIdentifier : SingleTokenizer = bind(NSCharacterSet(charactersInString: "+-").parser) { r in
    bind(divider) { _ in
        return pure(LispToken.Symbol(String(r)))
    }
}

let tokenSymbol : SingleTokenizer = identifier <|> uniqueIdentifier

let tokenVector : SingleTokenizer = bind(token("#")) { _ in
    bind(nextToken("(")) { _ in
        return pure(LispToken.VectorParentheses)
    }
}

let tokenQuote : SingleTokenizer = bind(token("'")) { _ in
    return pure(LispToken.Quote)
}

let tokenComma : SingleTokenizer = bind(token(",")) { _ in
    return pure(LispToken.Comma)
}

let tokenDot : SingleTokenizer = bind(token(".")) { _ in
    bind(divider) { _ in
        return pure(LispToken.Dot)
    }
}

// tokenizer

typealias LispTokenizer = Comb<Character, [LispToken]>.Parser

let lispTokenizer : LispTokenizer = oneOrMore(ignoreWhitespace(tokenSymbol <|> tokenBool <|> tokenInt <|> tokenDouble <|> tokenChar <|> tokenString <|> tokenLParentheses <|> tokenRParentheses <|> tokenVector <|> tokenQuote <|> tokenComma <|> tokenDot))

// parse s-expression

func parenthesesParser<T>(factory: () -> Comb<LispToken, T>.Parser) -> Comb<LispToken, T>.Parser {
    return bind(satisfy { (t: LispToken) in t.isLParentheses }) { L in
        bind(factory()) { insideList in
            bind(satisfy { (t: LispToken) in t.isRParentheses }) { R in
                return pure(insideList)
            }
        }
    }
}

func parseLispExpr() -> Comb<LispToken, SExpr>.Parser {
    let atom : Comb<LispToken, SExpr>.Parser = bind(consumer()) { r in
        if r.isRParentheses || r.isLParentheses {
            return zero()
        } else {
            return pure(r.expr)
        }
    }
    
    return bind(parenthesesParser { zeroOrMore(parseLispExpr() <|> atom) }){ (exprs: [SExpr]) in
        if exprs.count > 0 {
            //let head = exprs.removeAtIndex(0)
            let head = Pair()
            var pointer = head
            for cell in exprs {
                pointer.car = cell
                pointer.cdr = Pair()
                pointer = pointer.cdr as! Pair
            }
            return pure(head)
        } else {
            return pure(MNull())
        }
    }
}

//let test = [Character]("(set! \"Hi,\" \n \"hello\")")

//println(tokenLParentheses(test))

//println(tokenRParentheses(test))

//println(tokenVector(test))

//println(tokenQuote(test))

//println(tokenComma(test))

//println(tokenDot(test))

//println(tokenSymbol(test))

//println(tokenString(test))

//println(tokenChar(test))

//println(tokenBool(test))

//println(tokenInt(test))

//println(tokenDouble(test))

//println(lispTokenizer(test))



var b : [String] = ["hello"]

b.append("\n    ")

b.append("world")
