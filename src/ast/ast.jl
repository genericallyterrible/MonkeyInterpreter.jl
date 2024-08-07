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

struct LetStatement <: Statement
    token::Token
    name::Identifier
    value::Union{Expression,Nothing}  # TODO Expression
end

struct ReturnStatement <: Statement
    token::Token
    value::Union{Expression,Nothing}  # TODO Expression
end

struct ExpressionStatement <: Statement
    token::Token
    Expression::Union{Expression,Nothing}  # TODO Expression
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

function Base.print(io::IO, i::Identifier)
    print(io, i.value)
    return
end

function Base.print(io::IO, p::Program)
    for statement in p.statements
        print(io, statement)
    end
    return
end

function Base.print(io::IO, ls::LetStatement)
    print(io, token_literal(ls), " ", ls.name, " = ")
    if ls.value !== nothing  # TODO Expression
        print(io, ls.value)
    end
    print(io, ";")
    return
end

function Base.print(io::IO, rs::ReturnStatement)
    print(io, token_literal(rs), " ")
    if rs.value !== nothing  # TODO Expression
        print(io, rs.value)
    end
    print(io, ";")
    return
end

function Base.print(io::IO, es::ExpressionStatement)
    if es.Expression !== nothing  # TODO Expression
        print(io, es.Expression)
    end
    print(io, ";")
    return
end
