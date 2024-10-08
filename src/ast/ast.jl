import Base.print

abstract type Node end
abstract type Statement <: Node end
abstract type Expression <: Node end


struct Program <: Node
    statements::Vector{Statement}
end


struct Identifier <: Expression
    token::Token
    value::String
end
Identifier(token::Token) = Identifier(token, token.literal)

struct IntegerLiteral <: Expression
    token::Token
    value::Int64
end
IntegerLiteral(token::Token, value::String) = IntegerLiteral(token, parse(Int64, value))
IntegerLiteral(token::Token) = IntegerLiteral(token, token.literal)

struct BooleanLiteral <: Expression
    token::Token
    value::Bool
end
BooleanLiteral(token::Token) = BooleanLiteral(token, token.type == TokenTypes.TRUE)

struct PrefixExpression <: Expression
    token::Token
    operator::String
    right::Expression
end
PrefixExpression(token::Token, right::Expression) = PrefixExpression(token, token.literal, right)

struct InfixExpression <: Expression
    token::Token
    operator::String
    left::Expression
    right::Expression
end
InfixExpression(token::Token, left::Expression, right::Expression) = InfixExpression(token, token.literal, left, right)

struct BlockStatement <: Statement
    token::Token
    statements::Vector{Statement}
end

struct IfExpression <: Expression
    token::Token
    condition::Expression
    consequence::BlockStatement
    alternative::Union{BlockStatement,Nothing}
end

struct FunctionLiteral <: Expression
    token::Token
    parameters::Vector{Identifier}
    body::BlockStatement
end

struct CallExpression <: Expression
    token::Token
    callee::Union{Identifier,FunctionLiteral}
    arguments::Vector{Expression}
end

struct LetStatement <: Statement
    token::Token
    name::Identifier
    value::Expression
end

struct ReturnStatement <: Statement
    token::Token
    return_value::Expression
end

struct ExpressionStatement <: Statement
    token::Token
    expression::Expression
end


function token_literal(node::Node)::String
    throw("token_literal not implemented on $(typeof(node))")
end

function token_literal(node::Program)::String
    if length(node.statements) > 0
        return token_literal(node.statements[1])
    end
    return ""
end

function token_literal(node::Union{Statement,Expression})::String
    return node.token.literal
end


function statement_node(statement::Statement)
    throw("statement_node not implemented on $(typeof(statement))")
end

function expression_node(expression::Expression)
    throw("expression_node not implemented on $(typeof(expression))")
end

function Base.print(io::IO, node::Node)
    throw("Base.print not implemented on $(typeof(node))")
end

Base.print(io::IO, i::Identifier) = print(io, i.value)
Base.print(io::IO, il::IntegerLiteral) = print(io, il.value)
Base.print(io::IO, bl::BooleanLiteral) = print(io, bl.value)
Base.print(io::IO, pe::PrefixExpression) = print(io, "(", pe.operator, pe.right, ")")
Base.print(io::IO, ie::InfixExpression) = print(io, "(", ie.left, " ", ie.operator, " ", ie.right, ")")
Base.print(io::IO, ie::IfExpression) = begin
    print(io, "if", ie.condition, " ", ie.consequence)
    if !isnothing(ie.alternative)
        print(io, " else ", ie.alternative)
    end
end
Base.print(io::IO, fl::FunctionLiteral) = begin
    print(io, token_literal(fl), "(")
    join(io, fl.parameters, ", ")
    print(io, ")", fl.body)
end
Base.print(io::IO, ce::CallExpression) = begin
    print(io, ce.callee, "(")
    join(io, ce.arguments, ", ")
    print(io, ")")
end
Base.print(io::IO, b::BlockStatement) = print(io, b.statements...)
Base.print(io::IO, p::Program) = print(io, p.statements...)
Base.print(io::IO, ls::LetStatement) = print(io, token_literal(ls), " ", ls.name, " = ", ls.value, ";")
Base.print(io::IO, rs::ReturnStatement) = print(io, token_literal(rs), " ", rs.return_value, ";")
Base.print(io::IO, es::ExpressionStatement) = print(io, es.expression)
