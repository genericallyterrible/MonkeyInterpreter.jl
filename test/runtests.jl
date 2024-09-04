using MonkeyInterpreter
using Test

@testset "MonkeyInterpreter.jl" begin
    my_tests = [
        "ast.jl",
        "lexer.jl",
        "parser.jl",
    ]

    for my_test in my_tests
        include(my_test)
    end
end
