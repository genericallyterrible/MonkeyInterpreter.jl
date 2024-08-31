using Test, MonkeyInterpreter

@testset "Parser" begin
    @inline function test_parer_errors(p::Parser)
        for err in p.errors
            @error sprint(showerror, err)
        end
        @test length(p.errors) == 0
    end

    @inline function test_program_parse(input::String)::Program
        parser = Parser(input)
        program = Program(parser)

        test_parer_errors(parser)
        return program
    end

    @inline function test_identifier(exp::Expression, value::String)
        @test typeof(exp) == Identifier
        @test exp.value == value
        @test token_literal(exp) == value
    end

    @inline function test_integer_literal(exp::Expression, value::Int64)
        @test typeof(exp) == IntegerLiteral
        @test exp.value == value
        @test token_literal(exp) == string(value)
    end

    @inline function test_boolean_literal(exp::Expression, value::Bool)
        @test typeof(exp) == BooleanLiteral
        @test exp.value == value
        @test token_literal(exp) == string(value)
    end

    test_literal_expression(exp::Expression, value::String) = test_identifier(exp, value)
    test_literal_expression(exp::Expression, value::Int64) = test_integer_literal(exp, value)
    test_literal_expression(exp::Expression, value::Bool) = test_boolean_literal(exp, value)

    @inline function test_infix_expression(exp::Expression, left, operator::String, right)
        @test typeof(exp) == InfixExpression
        @test exp.operator == operator
        test_literal_expression(exp.left, left)
        test_literal_expression(exp.right, right)
    end

    @inline function test_let_statement(stmnt::Statement, name::String, value)
        @test typeof(stmnt) == LetStatement
        @test token_literal(stmnt) == "let"
        @test stmnt.name.value == name
        @test token_literal(stmnt.name) == name
        test_literal_expression(stmnt.value, value)
    end

    @inline function test_return_statement(stmnt::Statement, return_value)
        @test typeof(stmnt) == ReturnStatement
        @test token_literal(stmnt) == "return"
        test_literal_expression(stmnt.return_value, return_value)
    end

    @testset "Statements" begin
        @testset "Parse Let Statements" begin
            tests = [
                ("let x = 5;", "x", 5),
                ("let y = 10;", "y", 10),
                ("let foobar = 838383;", "foobar", 838383),
            ]

            for (input, name, value) in tests
                program = test_program_parse(input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                test_let_statement(stmnt, name, value)
            end
        end

        @testset "Parse Return Statements" begin
            tests = [
                ("return 5;", 5),
                ("return 10;", 10),
                ("return 993322;", 993322),
            ]

            for (input, return_value) in tests
                program = test_program_parse(input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                test_return_statement(stmnt, return_value)
            end
        end
    end

    @testset "Expressions" begin
        @testset "Parse Literal Expressions" begin
            tests = [
                ("5;" => 5),
                ("420;" => 420),
                ("2465468465054;" => 2465468465054),
                ("true;" => true),
                ("false;" => false),
                ("foobar;" => "foobar"),
                ("baz;" => "baz"),
            ]
            for (input, value) in tests
                program = test_program_parse(input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                @test typeof(stmnt) == ExpressionStatement
                test_literal_expression(stmnt.expression, value)
            end
        end

        @testset "Parse Prefix Expressions" begin
            tests = [
                ("!5;" => ("!", 5)),
                ("-15;" => ("-", 15)),
                ("!foobar;" => ("!", "foobar")),
                ("-foobar;" => ("-", "foobar")),
                ("!true;" => ("!", true)),
                ("!false;" => ("!", false)),
            ]
            for (input, (operator, value)) in tests
                program = test_program_parse(input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                @test typeof(stmnt) == ExpressionStatement

                exp = stmnt.expression
                @test typeof(exp) == PrefixExpression
                @test exp.operator == operator
                test_literal_expression(exp.right, value)
            end
        end

        @testset "Parse Infix Expressions" begin
            tests::Vector{Pair{String,Tuple{Any,String,Any}}} = [
                ("5 + 5;" => (5, "+", 5)),
                ("5 - 5;" => (5, "-", 5)),
                ("5 * 5;" => (5, "*", 5)),
                ("5 / 5;" => (5, "/", 5)),
                ("5 > 5;" => (5, ">", 5)),
                ("5 < 5;" => (5, "<", 5)),
                ("5 == 5;" => (5, "==", 5)),
                ("5 != 5;" => (5, "!=", 5)),
                ("foobar + barfoo;" => ("foobar", "+", "barfoo")),
                ("foobar - barfoo;" => ("foobar", "-", "barfoo")),
                ("foobar * barfoo;" => ("foobar", "*", "barfoo")),
                ("foobar / barfoo;" => ("foobar", "/", "barfoo")),
                ("foobar > barfoo;" => ("foobar", ">", "barfoo")),
                ("foobar < barfoo;" => ("foobar", "<", "barfoo")),
                ("foobar == barfoo;" => ("foobar", "==", "barfoo")),
                ("foobar != barfoo;" => ("foobar", "!=", "barfoo")),
                ("true == true;" => (true, "==", true)),
                ("true != false;" => (true, "!=", false)),
                ("false == false;" => (false, "==", false)),
            ]
            for (input, (left_value, operator, right_value)) in tests
                program = test_program_parse(input)
                @test length(program.statements) == 1

                stmnt = program.statements[1]
                @test typeof(stmnt) == ExpressionStatement

                exp = stmnt.expression
                @test typeof(exp) == InfixExpression
                @test exp.operator == operator
                test_literal_expression(exp.left, left_value)
                test_literal_expression(exp.right, right_value)
            end
        end

        @testset "Parse with Operator Precedence" begin
            tests::Vector{Tuple{String,String,Int}} = [
                (
                    "-a * b",
                    "((-a) * b)", 1
                ),
                (
                    "!-a",
                    "(!(-a))", 1
                ),
                (
                    "a + b - c",
                    "((a + b) - c)", 1
                ),
                (
                    "a * b * c",
                    "((a * b) * c)", 1
                ),
                (
                    "a * b / c",
                    "((a * b) / c)", 1
                ),
                (
                    "a + b / c",
                    "(a + (b / c))", 1
                ),
                (
                    "a + b * c + d / e - f",
                    "(((a + (b * c)) + (d / e)) - f)", 1
                ),
                (
                    "3 + 4; -5 * 5",
                    "(3 + 4)((-5) * 5)", 2
                ),
                (
                    "5 > 4 == 3 < 4",
                    "((5 > 4) == (3 < 4))", 1
                ),
                (
                    "5 < 4 != 3 > 4",
                    "((5 < 4) != (3 > 4))", 1
                ),
                (
                    "3 + 4 * 5 == 3 * 1 + 4 * 5",
                    "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))", 1
                ),
                (
                    "true",
                    "true", 1
                ),
                (
                    "false",
                    "false", 1
                ),
                (
                    "3 < 5 == true",
                    "((3 < 5) == true)", 1
                ),
                (
                    "3 > 5 == false",
                    "((3 > 5) == false)", 1
                ),
            ]
            for (input, expected, stmnts) in tests
                program = test_program_parse(input)
                @test length(program.statements) == stmnts
                @test string(program) == expected
            end
        end
    end
end
