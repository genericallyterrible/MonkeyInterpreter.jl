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

function next_token!(p::Parser)::Token
    p.current_token = p.peek_token
    p.peek_token = next_token!(p.lexer)
    return p.current_token
end

function parse_program!(p::Parser)::Program
    stmnts::Vector{Statement} = []
    while !current_token_is(p, TokenTypes.EOF)
        try
            push!(stmnts, parse_statement!(p))
        catch e
            if isa(e, ParseError)
                push!(p.errors, e)
            else
                rethrow()
            end
        end
        next_token!(p)
    end
    return Program(stmnts)
end

function parse_statement!(p::Parser)::Statement
    cur_type = p.current_token.type
    if cur_type == TokenTypes.LET
        return parse_let_statement!(p)
    end
    throw(UnsupportedStatementError(p.current_token.type))
end

function parse_let_statement!(p::Parser)::LetStatement
    let_tok = p.current_token

    ident_tok = expect_next_token!(p, TokenTypes.IDENT)
    ident = Identifier(ident_tok, ident_tok.literal)

    expect_next_token!(p, TokenTypes.ASSIGN)

    # TODO: We're skipping the expressions until we
    # encounter a semicolon
    while !current_token_is(p, TokenTypes.SEMICOLON)
        next_token!(p)
    end

    return LetStatement(let_tok, ident, ident)

end

"""
    current_token_is(p::Parser, t::TokenType)::Bool

Returns whether the current token in the Parser `p` has TokenType `t`.
"""
function current_token_is(p::Parser, t::TokenType)::Bool
    return p.current_token.type == t
end

"""
    peek_token_is(p::Parser, t::TokenType)::Bool

Returns whether the next token in the Parser `p` has TokenType `t`.
"""
function peek_token_is(p::Parser, t::TokenType)::Bool
    return p.peek_token.type == t
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
