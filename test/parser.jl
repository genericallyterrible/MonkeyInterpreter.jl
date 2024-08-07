using Test, MonkeyInterpreter

@testset "Parser" begin
    @inline function parse_input_to_program(input::String)::Program
        parser = Parser(input)
        program = parse_program!(parser)

        test_parer_errors(parser)
        return program
    end

    @inline function test_parer_errors(p::Parser)
        for err in p.errors
            @error sprint(showerror, err)
        end
        @test length(p.errors) == 0
    end

    @testset "Statements" begin
        @testset "Parse Let Statements" begin
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

            program = parse_input_to_program(input)
            @test length(program.statements) == length(tests)

            for (i, test) in enumerate(tests)
                stmnt = program.statements[i]
                @test token_literal(stmnt) == "let"
                @test typeof(stmnt) == LetStatement
                @test stmnt.name.value == test
                @test token_literal(stmnt.name) == test
            end

        end

        @testset failfast=true "Parse Return Statements" begin
            input = """
                return 5;
                return 10;
                return 993322;
            """

            program = parse_input_to_program(input)
            @test length(program.statements) == 3

            for stmnt in program.statements
                @test token_literal(stmnt) == "return"
                @test typeof(stmnt) == ReturnStatement
            end
        end
    end

    @testset "Expressions" begin
        @testset "Parse Identifier Expression" begin
            program = parse_input_to_program("foobar;")
            @test length(program.statements) == 1

            stmnt = program.statements[1]
            @test typeof(stmnt) == ExpressionStatement

            ident = stmnt.expression
            @test typeof(ident) == Identifier
            @test ident.value == "foobar"
            @test token_literal(ident) == "foobar"
        end

        @inline function test_integer_literal(exp::Expression, value::Int64)
            @test typeof(exp) == IntegerLiteral
            @test exp.value == value
            @test token_literal(exp) == string(value)
        end

        @testset "Parse IntegerLiteral" begin
            program = parse_input_to_program("5;")
            @test length(program.statements) == 1

            stmnt = program.statements[1]
            @test typeof(stmnt) == ExpressionStatement
            test_integer_literal(stmnt.expression, 5)
        end

        @testset "Parse Prefix Expressions" begin
            struct PrefixTest
                input::String
                operator::String
                integer_value::Int64
            end
            tests = splat(PrefixTest).((
                ("!5;", "!", 5),
                ("-15;", "-", 15),
            ))
            for test in tests
                program = parse_input_to_program(test.input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                @test typeof(stmnt) == ExpressionStatement

                exp = stmnt.expression
                @test typeof(exp) == PrefixExpression
                @test exp.operator == test.operator
                test_integer_literal(exp.right, test.integer_value)
            end
        end

        @testset "Parse Infix Expressions" begin
            struct InfixTest
                input::String
                left_value::Int64
                operator::String
                right_value::Int64
            end
            tests = splat(InfixTest).((
                ("5 + 5;", 5, "+", 5),
                ("5 - 5;", 5, "-", 5),
                ("5 * 5;", 5, "*", 5),
                ("5 / 5;", 5, "/", 5),
                ("5 > 5;", 5, ">", 5),
                ("5 < 5;", 5, "<", 5),
                ("5 == 5;", 5, "==", 5),
                ("5 != 5;", 5, "!=", 5),
            ))
            for test in tests
                program = parse_input_to_program(test.input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                @test typeof(stmnt) == ExpressionStatement

                exp = stmnt.expression
                @test typeof(exp) == InfixExpression
                @test exp.operator == test.operator
                test_integer_literal(exp.left, test.left_value)
                test_integer_literal(exp.right, test.right_value)
            end
        end

        @testset "Parse with Operator Precedence" begin
            tests::Vector{Tuple{String,String,Int}} = [
                ("-a * b", "((-a) * b)", 1),
                ("!-a", "(!(-a))", 1),
                ("a + b - c", "((a + b) - c)", 1),
                ("a * b * c", "((a * b) * c)", 1),
                ("a * b / c", "((a * b) / c)", 1),
                ("a + b / c", "(a + (b / c))", 1),
                ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)", 1),
                ("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)", 2),
                ("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))", 1),
                ("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))", 1),
                ("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))", 1),
            ]
            for (input, expected, stmnts) in tests
                program = parse_input_to_program(input)
                @test length(program.statements) == stmnts
                @test string(program) == expected
            end
        end
    end
end
