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
    value::Nothing  # TODO Expression
end

struct ReturnStatement <: Statement
    token::Token
    value::Nothing  # TODO Expression
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
