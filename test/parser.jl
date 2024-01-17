using Test, MonkeyInterpreter

@testset "Parser" begin
    function test_parer_errors(p::Parser)
        try
            @test length(p.errors) == 0
        catch
            for err in p.errors
                @error sprint(showerror, err)
            end
            throw(e)
        end
    end

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

        parser = Parser(input)
        program = parse_program!(parser)

        test_parer_errors(parser)

        @test length(program.statements) == length(tests)

        for (i, test) in enumerate(tests)
            stmnt = program.statements[i]
            @test token_literal(stmnt) == "let"
            @test typeof(stmnt) == LetStatement
            @test stmnt.name.value == test
            @test token_literal(stmnt.name) == test
        end

    end

    @testset failfast = true "Parse Return Statements" begin
        input = """
            return 5;
            return 10;
            return 993322;
        """

        parser = Parser(input)
        program = parse_program!(parser)

        test_parer_errors(parser)

        @test length(program.statements) == 3

        for stmnt in program.statements
            @test token_literal(stmnt) == "return"
            @test typeof(stmnt) == ReturnStatement
        end
    end

end
