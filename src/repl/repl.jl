module REPL

export start

import ..Parser, ..Program, ..show_errors

const PROMPT = ">> "

function start(in::IO=stdin, out::IO=stdout)
    while true
        try
            print(out, PROMPT)
            line = readline(in)

            parser = Parser(line)
            prog = Program(parser)
            if length(parser.errors) > 0
                show_errors(parser)
                continue
            end

            println(prog)
        catch e
            if isa(e, InterruptException)
                break
            end
            println(out, e)
        end
    end
end

end  # module REPL
