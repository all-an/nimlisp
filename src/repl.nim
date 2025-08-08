## REPL (Read-Eval-Print Loop) module for NimLisp
## 
## This module provides the interactive environment for NimLisp,
## allowing users to enter expressions and see their evaluated results.
## It integrates the lexer, parser, and evaluator components.

import parser
import evaluator
import ast
import strutils

## Evaluates a single NimLisp expression and returns the result as a string
## 
## This function handles the complete pipeline from source code to result:
## parsing, evaluation, and formatting the output for display.
## 
## Args:
##   input: The NimLisp source code string to evaluate
## 
## Returns:
##   A string containing either the evaluated result or error message
proc evalExpression*(input: string): string =
    # Parse the input
    let parseResult = parseExpression(input)
    if not parseResult.isOk:
        return "Error: " & parseResult.error

    # Evaluate the parsed expression
    let evalResult = evaluate(parseResult.value)
    if not evalResult.isOk:
        return "Error: " & evalResult.error

    # Return the string representation of the result
    return $evalResult.value

## Prints the NimLisp banner and welcome message
## 
## Displays information about the language and basic usage instructions
## for new users entering the REPL environment.
proc printBanner() =
    echo "NimLisp REPL v0.1.0"
    echo "Pure functional, metaprogramming, homoiconic systems language"
    echo "Type expressions to evaluate them, or 'quit' to exit."
    echo ""

## Starts the interactive REPL session
## 
## This function runs the main read-eval-print loop, continuously
## prompting for user input, evaluating expressions, and displaying
## results until the user chooses to quit.
proc startRepl*() =
    printBanner()

    while true:
        try:
            # Read input from user
            stdout.write("nimlisp> ")
            stdout.flushFile()
            let line = stdin.readLine().strip()

            # Check for quit command
            if line == "quit" or line == "exit":
                echo "Goodbye!"
                break

            # Skip empty lines
            if line == "":
                continue

            # Evaluate and print result
            let result = evalExpression(line)
            echo result
        except EOFError:
            # EOF (Ctrl+D) pressed
            echo "\nGoodbye!"
            break
        except IOError:
            # Handle other I/O errors
            echo "\nGoodbye!"
            break

## Main entry point when run as executable
## 
## Starts the REPL when this module is run directly from the command line.
when isMainModule:
    startRepl()