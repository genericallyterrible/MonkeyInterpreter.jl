using Test, MonkeyInterpreter

@testset "AST" begin
    @testset failfast = true "Simple Program Stringification" begin
        program = Program([
            LetStatement(
                Token(TokenTypes.LET, "let"),
                Identifier(
                    Token(TokenTypes.IDENT, "myVar"),
                    "myVar",
                ),
                Identifier(
                    Token(TokenTypes.IDENT, "anotherVar"),
                    "anotherVar",
                ),
            ),
        ])

        @test string(program) == "let myVar = anotherVar;"
    end
end
