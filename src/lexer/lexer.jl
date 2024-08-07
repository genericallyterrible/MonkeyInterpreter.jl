mutable struct Lexer
    const input::String

    position::Int       # current position in input (points to current char)
    read_position::Int  # current reading position in input (after current char)
    ch::Char            # current char under examination

    function Lexer(input::AbstractString)::Lexer
        l = new(input, 0, 1)
        readchar!(l)
        return l
    end
end

"""
    readchar!(l::Lexer)::Nothing

Read the next available character and advance the lexer.
"""
function readchar!(l::Lexer)::Nothing
    l.ch = peekchar(l)
    l.position = l.read_position
    l.read_position += 1
    return nothing
end

"""
    peekchar(l::Lexer)::Char

Returns the next character available to lex without advancing the lexer.
"""
function peekchar(l::Lexer)::Char
    return l.read_position <= length(l.input) ? l.input[l.read_position] : '\0'
end

"""
    next_token!(l::Lexer)::Token

Look at `l`'s current character under examination, match
it to the appropriate token, advance `l`, and return the token.

# Example usage:
```jldoctest
julia> l = Lexer("+")
Lexer("+", 1, 2, '\0')

julia> next_token!(l)
Token(TokenTypes.PLUS, "+")

julia> next_token!(l)
Token(TokenTypes.EOF, "")
```
"""
function next_token!(l::Lexer)::Token
    skip_whitespace!(l)
    if l.ch == '='
        if peekchar(l) == '='
            ch = l.ch
            readchar!(l)
            tok = Token(TokenTypes.EQ, ch * l.ch)
        else
            tok = Token(TokenTypes.ASSIGN, l.ch)
        end
    elseif l.ch == '+'
        tok = Token(TokenTypes.PLUS, l.ch)
    elseif l.ch == '-'
        tok = Token(TokenTypes.MINUS, l.ch)
    elseif l.ch == '!'
        if peekchar(l) == '='
            ch = l.ch
            readchar!(l)
            tok = Token(TokenTypes.NOT_EQ, ch * l.ch)
        else
            tok = Token(TokenTypes.BANG, l.ch)
        end
    elseif l.ch == '/'
        tok = Token(TokenTypes.SLASH, l.ch)
    elseif l.ch == '*'
        tok = Token(TokenTypes.ASTERISK, l.ch)
    elseif l.ch == '<'
        tok = Token(TokenTypes.LT, l.ch)
    elseif l.ch == '>'
        tok = Token(TokenTypes.GT, l.ch)
    elseif l.ch == ';'
        tok = Token(TokenTypes.SEMICOLON, l.ch)
    elseif l.ch == ','
        tok = Token(TokenTypes.COMMA, l.ch)
    elseif l.ch == '('
        tok = Token(TokenTypes.LPAREN, l.ch)
    elseif l.ch == ')'
        tok = Token(TokenTypes.RPAREN, l.ch)
    elseif l.ch == '{'
        tok = Token(TokenTypes.LBRACE, l.ch)
    elseif l.ch == '}'
        tok = Token(TokenTypes.RBRACE, l.ch)
    elseif l.ch == '\0'
        tok = Token(TokenTypes.EOF, "")
    else
        if is_ident_char(l.ch)
            literal::String = read_identifier!(l)
            type::TokenType = look_up_ident(literal)
            return Token(type, literal)
        elseif isdigit(l.ch)
            return Token(TokenTypes.INT, read_digit!(l))
        else
            tok = Token(TokenTypes.ILLEGAL, l.ch)
        end
    end

    readchar!(l)
    return tok
end

function read_identifier!(l::Lexer)::String
    position = l.position
    while is_ident_char(l.ch)
        readchar!(l)
    end
    return l.input[position:l.position-1]
end

function is_ident_char(ch::Char)::Bool
    return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
end

function skip_whitespace!(l::Lexer)::Nothing
    while l.ch in [' ', '\t', '\n', '\r']
        readchar!(l)
    end
end

function read_digit!(l::Lexer)::String
    position = l.position
    while isdigit(l.ch)
        readchar!(l)
    end
    return l.input[position:l.position-1]
end

Base.iterate(l::Lexer) = begin
    tok = next_token!(l)
    return (tok, tok)
end

Base.iterate(l::Lexer, state::Token) = begin
    if state.type == TokenTypes.EOF
        return nothing
    end
    tok = next_token!(l)
    return (tok, tok)
end

Base.eltype(::Type{Lexer}) = Token
