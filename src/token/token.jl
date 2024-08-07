module TokenTypes
export TokenType
@enum TokenType begin
    ILLEGAL
    EOF

    # Identifiers + literals
    IDENT      # add, foobar, x, y, ...
    INT        # 1343456

    # Operators
    ASSIGN     # "="
    PLUS       # "+"
    MINUS      # "-"
    BANG       # "!"
    ASTERISK   # "*"
    SLASH      # "/"

    LT         # "<"
    GT         # ">"

    EQ         # "=="
    NOT_EQ     # "!="

    # Delimiters
    COMMA      # ","
    SEMICOLON  # ";"

    LPAREN     # "("
    RPAREN     # ")"
    LBRACE     # "{"
    RBRACE     # "}"

    # Keywords
    FUNCTION   # "FUNCTION"
    LET        # "LET"
    TRUE       # "TRUE"
    FALSE      # "FALSE"
    IF         # "IF"
    ELSE       # "ELSE"
    RETURN     # "RETURN"
end
end  # TokenTypes

import .TokenTypes.TokenType

struct Token
    type::TokenType
    literal::String
end

Token(Type::TokenType, Literal::AbstractChar) = Token(Type, string(Literal))

keywords::Dict{String,TokenType} = Dict(
    "fn" => TokenTypes.FUNCTION,
    "let" => TokenTypes.LET,
    "true" => TokenTypes.TRUE,
    "false" => TokenTypes.FALSE,
    "if" => TokenTypes.IF,
    "else" => TokenTypes.ELSE,
    "return" => TokenTypes.RETURN,
)

function look_up_ident(ident::String)
    return get(keywords, ident, TokenTypes.IDENT)
end
