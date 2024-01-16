export REPL


module REPL

export start

import ..Lexer

const PROMPT = ">> "

function start(in::IO=stdin, out::IO=stdout)
    while true
        try
            print(out, PROMPT)
            line = readline(in)

            l = Lexer(line)
            for tok in l
                println(out, "$tok")
            end
        catch e
            if isa(e, InterruptException)
                break
            end
            println(out, e)
        end
    end
end

end  # module REPL
