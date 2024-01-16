using MonkeyInterpreter.REPL

println("Hello, $(ENV["USERNAME"])! This is the Monkey programming language!")
println("Feel free to type in commands")
REPL.start()
