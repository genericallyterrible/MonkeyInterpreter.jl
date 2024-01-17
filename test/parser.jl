using Test, MonkeyInterpreter

@testset "Parser" begin


    @testset failfast = true "Parse Let Statements" begin
        input = """
            let x = 5;
            let y = 10;
            let foobar = 838383;
        """
        tests = (
            "x",
            "y",
            "foobar",
        )

        parser = Parser(Lexer(input))
        program = parse_program!(parser)

        try
            @test length(parser.errors) == 0
        catch
            for err in parser.errors
                @error sprint(showerror, err)
            end
            throw(e)
        end

        @test length(program.statements) == length(tests)

        for (i, test) in enumerate(tests)
            stmnt = program.statements[i]
            @test token_literal(stmnt) == "let"
            @test typeof(stmnt) == LetStatement
            @test stmnt.name.value == test
            @test token_literal(stmnt.name) == test
        end

    end

end
