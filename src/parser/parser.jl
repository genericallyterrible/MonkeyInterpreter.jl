module Precedences
export Precedence
@enum Precedence begin
    LOWEST
    EQUALS       # ==
    LESSGREATER  # < or >
    SUM          # +
    PRODUCT      # *
    PREFIX       # -x or !x
    CALL         # my_function(x)
end
end  # Precedences

import .Precedences.Precedence

const OPERATOR_PRECEDENCE::Dict{TokenType,Precedence} = Dict(
    TokenTypes.EQ => Precedences.EQUALS,
    TokenTypes.NOT_EQ => Precedences.EQUALS,
    TokenTypes.LT => Precedences.LESSGREATER,
    TokenTypes.GT => Precedences.LESSGREATER,
    TokenTypes.PLUS => Precedences.SUM,
    TokenTypes.MINUS => Precedences.SUM,
    TokenTypes.SLASH => Precedences.PRODUCT,
    TokenTypes.ASTERISK => Precedences.PRODUCT,
    TokenTypes.LPAREN => Precedences.CALL,
)


abstract type ParseError <: Exception end

struct ExpectedTokenError <: ParseError
    expected::TokenType
    got::TokenType
end

function Base.showerror(io::IO, e::ExpectedTokenError)
    print(io, nameof(typeof(e)), ": expected '", e.expected, "', got '", e.got, "'")
end

struct UnsupportedStatementError <: ParseError
    type::TokenType
end

function Base.showerror(io::IO, e::UnsupportedStatementError)
    print(io, nameof(typeof(e)), ": unsupported statement beginning with '", e.type, "'")
end

struct UnsupportedPrefixError <: ParseError
    type::TokenType
end

function Base.showerror(io::IO, e::UnsupportedPrefixError)
    print(io, nameof(typeof(e)), ": cannot parse prefix statement for token type '", e.type, "'")
end

struct UnsupportedInfixError <: ParseError
    type::TokenType
end

function Base.showerror(io::IO, e::UnsupportedInfixError)
    print(io, nameof(typeof(e)), ": cannot parse infix statement for token type '", e.type, "'")
end

struct IntegerLiteralParseError <: ParseError
    token::Token
end

function Base.showerror(io::IO, e::IntegerLiteralParseError)
    print(io, nameof(typeof(e)), ": cannot parse '", e.token.literal, "' as IntegerLiteral")
end

mutable struct Parser
    const lexer::Lexer

    current_token::Token
    peek_token::Token
    errors::Vector{Exception}

    function Parser(l::Lexer)::Parser
        cur = next_token!(l)
        next = next_token!(l)
        return new(l, cur, next, [])
    end

    function Parser(input::AbstractString)::Parser
        l = Lexer(input)
        return Parser(l)
    end
end

Program(p::Parser) = Program([stmnt for stmnt in p])
Program(l::Lexer) = Program(Parser(l))
Program(input::AbstractString) = Program(Parser(input))

function show_errors(io::IO, p::Parser)
    for err in p.errors
        printstyled(io, "ERROR: "; color=:red)
        showerror(io, err)
        println(io)
    end
end
show_errors(p::Parser) = show_errors(stdout, p)

"""
    next_token!(p::Parser)::Token

Advances the underlying lexer to the next token and return the new current token.
"""
function next_token!(p::Parser)::Token
    p.current_token = p.peek_token
    p.peek_token = next_token!(p.lexer)
    return p.current_token
end

"""
    current_token_is(p::Parser, t::TokenType)::Bool

Returns whether the current token in the Parser `p` has TokenType `t`.
"""
@inline function current_token_is(p::Parser, t::TokenType)::Bool
    return p.current_token.type == t
end

"""
    peek_token_is(p::Parser, t::TokenType)::Bool

Returns whether the next token in the Parser `p` has TokenType `t`.
"""
@inline function peek_token_is(p::Parser, t::TokenType)::Bool
    return p.peek_token.type == t
end

function expect_current_token(p::Parser, t::TokenType)::Token
    if !current_token_is(p, t)
        throw(ExpectedTokenError(t, p.current_token.type))
    end
    return p.current_token
end

"""
    expect_next_token!(p::Parser, t::TokenType)::Token

Expect the next token in the Parser `p` to have TokenType `t`.
If the type of the next token matches the expected type, the parser
advances to the next token and returns it.
Otherwise an `ExpectedTokenError` is thrown.
"""
function expect_next_token!(p::Parser, t::TokenType)::Token
    if !peek_token_is(p, t)
        throw(ExpectedTokenError(t, p.peek_token.type))
    end
    return next_token!(p)
end

@inline function current_precedence(p::Parser)::Precedence
    return get(OPERATOR_PRECEDENCE, p.current_token.type, Precedences.LOWEST)
end

@inline function peek_precedence(p::Parser)::Precedence
    return get(OPERATOR_PRECEDENCE, p.peek_token.type, Precedences.LOWEST)
end

function Base.iterate(p::Parser, state::Nothing=nothing)
    while !current_token_is(p, TokenTypes.EOF)
        try
            return (parse_statement!(p), nothing)
        catch e
            if isa(e, ParseError)
                push!(p.errors, e)
            else
                rethrow()
            end
        finally
            next_token!(p)
        end
    end
    return nothing
end

Base.eltype(::Type{Parser}) = Statement
Base.IteratorSize(::Parser) = Base.SizeUnknown()

"""
    parse_statement!(p::Parser)::Statement

Parses a single statement from the parser based on the current token type.
"""
function parse_statement!(p::Parser)::Statement
    cur_type = p.current_token.type
    stmnt = if cur_type == TokenTypes.LET
        parse_let_statement!(p)
    elseif cur_type == TokenTypes.RETURN
        parse_return_statement!(p)
    else
        parse_expression_statement!(p)
    end

    if peek_token_is(p, TokenTypes.SEMICOLON)
        next_token!(p)
    end

    return stmnt
end

"""
    parse_let_statement!(p::Parser)::LetStatement

Parses a `LET` statement from the parser.
"""
function parse_let_statement!(p::Parser)::LetStatement
    tok = p.current_token
    ident = Identifier(expect_next_token!(p, TokenTypes.IDENT))

    expect_next_token!(p, TokenTypes.ASSIGN)
    next_token!(p)

    expr = parse_expression!(p, Precedences.LOWEST)
    return LetStatement(tok, ident, expr)
end

"""
    parse_return_statement!(p::Parser)::ReturnStatement

Parses a `RETURN` statement from the parser.
"""
function parse_return_statement!(p::Parser)::ReturnStatement
    tok = p.current_token

    next_token!(p)

    expr = parse_expression!(p, Precedences.LOWEST)
    return ReturnStatement(tok, expr)
end

function parse_expression_statement!(p::Parser)::ExpressionStatement
    return ExpressionStatement(p.current_token, parse_expression!(p, Precedences.LOWEST))
end

function parse_expression!(p::Parser, precedence::Precedence)::Expression
    prefix = get(PREFIX_PARSE_FNS, p.current_token.type, nothing)
    if prefix === nothing
        throw(UnsupportedPrefixError(p.current_token.type))
    end
    left_exp = prefix(p)

    while !peek_token_is(p, TokenTypes.SEMICOLON) && precedence < peek_precedence(p)
        infix = get(INFIX_PARSE_FNS, p.peek_token.type, nothing)
        if infix === nothing
            throw(UnsupportedInfixError(p.current_token.type))
        end
        next_token!(p)
        left_exp = infix(p, left_exp)
    end

    return left_exp
end

function parse_identifier(p::Parser)::Identifier
    return Identifier(p.current_token)
end

function parse_integer_literal(p::Parser)::IntegerLiteral
    try
        return IntegerLiteral(p.current_token)
    catch
        throw(IntegerLiteralParseError(p.current_token))
    end
end

function parse_prefix_expression!(p::Parser)::PrefixExpression
    tok = p.current_token
    next_token!(p)
    right = parse_expression!(p, Precedences.PREFIX)
    return PrefixExpression(tok, right)
end

function parse_boolean_literal(p::Parser)::BooleanLiteral
    return BooleanLiteral(p.current_token)
end

function parse_grouped_expression!(p::Parser)::Expression
    next_token!(p)
    exp = parse_expression!(p, Precedences.LOWEST)
    expect_next_token!(p, TokenTypes.RPAREN)
    return exp
end

function parse_infix_expression!(p::Parser, left::Expression)::InfixExpression
    tok = p.current_token
    prec = current_precedence(p)
    next_token!(p)
    right = parse_expression!(p, prec)
    return InfixExpression(tok, left, right)
end

function parse_if_expression!(p::Parser)::IfExpression
    tok = p.current_token

    expect_next_token!(p, TokenTypes.LPAREN)
    condition = parse_expression!(p, Precedences.LOWEST)
    expect_current_token(p, TokenTypes.RPAREN)

    expect_next_token!(p, TokenTypes.LBRACE)
    consequence = parse_block_statement!(p)

    alternative = nothing
    if peek_token_is(p, TokenTypes.ELSE)
        next_token!(p)
        expect_next_token!(p, TokenTypes.LBRACE)
        alternative = parse_block_statement!(p)
    end

    return IfExpression(tok, condition, consequence, alternative)
end

function parse_function_parameters!(p::Parser)::Vector{Identifier}
    idents::Vector{Identifier} = []
    next_token!(p)

    if current_token_is(p, TokenTypes.RPAREN)
        return idents
    end

    push!(idents, Identifier(p.current_token))

    while (peek_token_is(p, TokenTypes.COMMA))
        next_token!(p)
        next_token!(p)
        push!(idents, Identifier(p.current_token))
    end

    expect_next_token!(p, TokenTypes.RPAREN)

    return idents
end

function parse_function_literal!(p::Parser)::FunctionLiteral
    tok = p.current_token

    expect_next_token!(p, TokenTypes.LPAREN)
    params = parse_function_parameters!(p)
    expect_current_token(p, TokenTypes.RPAREN)

    expect_next_token!(p, TokenTypes.LBRACE)
    body = parse_block_statement!(p)

    return FunctionLiteral(tok, params, body)
end

function parse_block_statement!(p::Parser)::BlockStatement
    tok = p.current_token
    stmnts = []

    next_token!(p)
    while !(current_token_is(p, TokenTypes.RBRACE) || current_token_is(p, TokenTypes.EOF))
        push!(stmnts, parse_statement!(p))
        next_token!(p)
    end

    return BlockStatement(tok, stmnts)
end

function parse_call_arguments!(p::Parser)::Vector{Expression}
    args::Vector{Expression} = []
    next_token!(p)

    if current_token_is(p, TokenTypes.RPAREN)
        return args
    end

    push!(args, parse_expression!(p, Precedences.LOWEST))

    while (peek_token_is(p, TokenTypes.COMMA))
        next_token!(p)
        next_token!(p)
        push!(args, parse_expression!(p, Precedences.LOWEST))
    end

    expect_next_token!(p, TokenTypes.RPAREN)

    return args
end

function parse_call_expression!(p::Parser, callee::Union{Identifier,FunctionLiteral})::CallExpression
    return CallExpression(p.current_token, callee, parse_call_arguments!(p))
end

const PREFIX_PARSE_FNS::Dict{TokenType,Function} = Dict(
    TokenTypes.IDENT => parse_identifier,
    TokenTypes.INT => parse_integer_literal,
    TokenTypes.BANG => parse_prefix_expression!,
    TokenTypes.MINUS => parse_prefix_expression!,
    TokenTypes.TRUE => parse_boolean_literal,
    TokenTypes.FALSE => parse_boolean_literal,
    TokenTypes.LPAREN => parse_grouped_expression!,
    TokenTypes.IF => parse_if_expression!,
    TokenTypes.FUNCTION => parse_function_literal!,
)

const INFIX_PARSE_FNS::Dict{TokenType,Function} = Dict(
    TokenTypes.PLUS => parse_infix_expression!,
    TokenTypes.MINUS => parse_infix_expression!,
    TokenTypes.SLASH => parse_infix_expression!,
    TokenTypes.ASTERISK => parse_infix_expression!,
    TokenTypes.EQ => parse_infix_expression!,
    TokenTypes.NOT_EQ => parse_infix_expression!,
    TokenTypes.LT => parse_infix_expression!,
    TokenTypes.GT => parse_infix_expression!,
    TokenTypes.LPAREN => parse_call_expression!,
)
