using Test, MonkeyInterpreter

@testset "Lexer" begin
    function test_next_token(input::String, expects::NTuple{N,Token}) where {N}
        l = Lexer(input)
        for expect::Token in expects
            pos = l.position
            tok = nexttoken!(l)
            try
                @test tok == expect
            catch e
                @error """Lexer failed to match token.
                    Expected: $(expect)
                    Got:      $(tok)
                    At:       [$pos:$(l.position-1)]
                    "$input"
                    """ tok
                throw(e)
            end
        end
    end

    @testset failfast = true "Lex Simple Symbols" begin
        input = "=+(){},;"
        tests = splat(Token).((
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.PLUS, "+"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.SEMICOLON, ";"),
        ))

        test_next_token(input, tests)
    end

    @testset failfast = true "Lex Small Program" begin
        input = """let five = 5;
            let ten = 10;

            let add = fn(x, y) {
                x + y;
            };

            let result = add(five, ten);
        """
        tests = splat(Token).((
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "10"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.FUNCTION, "fn"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.PLUS, "+"),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "result"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.EOF, ""),
        ))

        test_next_token(input, tests)
    end

    @testset failfast = true "Lex Some Gibberish" begin
        input = """let five = 5;
            let ten = 10;

            let add = fn(x, y) {
                x + y;
            };

            let result = add(five, ten);
            !-/*5;
            5 < 10 > 5;
        """
        tests = splat(Token).((
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "10"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.FUNCTION, "fn"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.PLUS, "+"),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "result"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.BANG, "!"),
            (TokenTypes.MINUS, "-"),
            (TokenTypes.SLASH, "/"),
            (TokenTypes.ASTERISK, "*"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.INT, "5"),
            (TokenTypes.LT, "<"),
            (TokenTypes.INT, "10"),
            (TokenTypes.GT, ">"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.EOF, ""),
        ))

        test_next_token(input, tests)
    end

    @testset failfast = true "Lex New Keywords" begin
        input = """let five = 5;
            let ten = 10;

            let add = fn(x, y) {
                x + y;
            };

            let result = add(five, ten);
            !-/*5;
            5 < 10 > 5;

            if (5 < 10) {
                return true;
            } else {
                return false;
            }
        """
        tests = splat(Token).((
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "10"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.FUNCTION, "fn"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.PLUS, "+"),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "result"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.BANG, "!"),
            (TokenTypes.MINUS, "-"),
            (TokenTypes.SLASH, "/"),
            (TokenTypes.ASTERISK, "*"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.INT, "5"),
            (TokenTypes.LT, "<"),
            (TokenTypes.INT, "10"),
            (TokenTypes.GT, ">"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.IF, "if"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.INT, "5"),
            (TokenTypes.LT, "<"),
            (TokenTypes.INT, "10"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.RETURN, "return"),
            (TokenTypes.TRUE, "true"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.ELSE, "else"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.RETURN, "return"),
            (TokenTypes.FALSE, "false"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.EOF, ""),
        ))

        test_next_token(input, tests)
    end

    @testset failfast = true "Lex Multi-Char Tokens" begin
        input = """let five = 5;
            let ten = 10;

            let add = fn(x, y) {
                x + y;
            };

            let result = add(five, ten);
            !-/*5;
            5 < 10 > 5;

            if (5 < 10) {
                return true;
            } else {
                return false;
            }

            10 == 10;
            10 != 9;
        """
        tests = splat(Token).((
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.INT, "10"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.FUNCTION, "fn"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.IDENT, "x"),
            (TokenTypes.PLUS, "+"),
            (TokenTypes.IDENT, "y"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.LET, "let"),
            (TokenTypes.IDENT, "result"),
            (TokenTypes.ASSIGN, "="),
            (TokenTypes.IDENT, "add"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.IDENT, "five"),
            (TokenTypes.COMMA, ","),
            (TokenTypes.IDENT, "ten"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.BANG, "!"),
            (TokenTypes.MINUS, "-"),
            (TokenTypes.SLASH, "/"),
            (TokenTypes.ASTERISK, "*"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.INT, "5"),
            (TokenTypes.LT, "<"),
            (TokenTypes.INT, "10"),
            (TokenTypes.GT, ">"),
            (TokenTypes.INT, "5"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.IF, "if"),
            (TokenTypes.LPAREN, "("),
            (TokenTypes.INT, "5"),
            (TokenTypes.LT, "<"),
            (TokenTypes.INT, "10"),
            (TokenTypes.RPAREN, ")"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.RETURN, "return"),
            (TokenTypes.TRUE, "true"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.ELSE, "else"),
            (TokenTypes.LBRACE, "{"),
            (TokenTypes.RETURN, "return"),
            (TokenTypes.FALSE, "false"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.RBRACE, "}"),
            (TokenTypes.INT, "10"),
            (TokenTypes.EQ, "=="),
            (TokenTypes.INT, "10"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.INT, "10"),
            (TokenTypes.NOT_EQ, "!="),
            (TokenTypes.INT, "9"),
            (TokenTypes.SEMICOLON, ";"),
            (TokenTypes.EOF, ""),
        ))

        test_next_token(input, tests)
    end
end
