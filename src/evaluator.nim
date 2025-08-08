## Evaluator module for NimLisp expression evaluation
## 
## This module implements the core evaluation engine that executes
## NimLisp expressions. It handles arithmetic operations, quote forms,
## and provides the foundation for the functional evaluation model.

import ast
import parser

## Forward declarations for arithmetic operations
proc evaluateAddition(args: seq[Node]): ParseResult[Node]
proc evaluateSubtraction(args: seq[Node]): ParseResult[Node]
proc evaluateMultiplication(args: seq[Node]): ParseResult[Node]
proc evaluateDivision(args: seq[Node]): ParseResult[Node]

## Evaluates a NimLisp AST node and returns the result
## 
## This is the main evaluation function that handles all node types.
## It implements the pure functional evaluation semantics where
## expressions evaluate to values without side effects.
## 
## Args:
##   node: The AST Node to evaluate
## 
## Returns:
##   ParseResult containing the evaluated Node or error message
proc evaluate*(node: Node): ParseResult[Node] =
    case node.kind
    of nkNumber, nkString, nkBool:
        # Self-evaluating literals
        return ok(node)

    of nkQuote:
        # Quote returns the quoted expression without evaluation
        return ok(node.quoted)

    of nkList:
        # Handle empty list
        if node.elements.len == 0:
            return ok(newList(@[]))

        # Get the function (first element)
        let functionNode = node.elements[0]

        # Check if it's a known built-in function
        if functionNode.kind == nkSymbol:
            case functionNode.symbolName
            of "+":
                return evaluateAddition(node.elements[1..^1])
            of "-":
                return evaluateSubtraction(node.elements[1..^1])
            of "*":
                return evaluateMultiplication(node.elements[1..^1])
            of "/":
                return evaluateDivision(node.elements[1..^1])
            else:
                return err[Node]("Unknown function: " & functionNode.symbolName)
        else:
            return err[Node]("First element of list must be a function symbol")

    of nkSymbol:
        # Undefined symbols are errors in our simple evaluator
        return err[Node]("Undefined symbol: " & node.symbolName)

## Evaluates addition of multiple numbers
## 
## Implements the + operator for summing numeric values.
## All arguments must be numbers.
## 
## Args:
##   args: Sequence of Node arguments to add
## 
## Returns:
##   ParseResult containing the sum as a number Node or error
proc evaluateAddition(args: seq[Node]): ParseResult[Node] =
    if args.len == 0:
        return ok(newNumber(0))

    var sum = 0
    for arg in args:
        let evalResult = evaluate(arg)
        if not evalResult.isOk:
            return evalResult

        let evaluatedArg = evalResult.value
        if evaluatedArg.kind != nkNumber:
            return err[Node]("Addition requires numeric arguments")

        sum += evaluatedArg.numberValue

    return ok(newNumber(sum))

## Evaluates subtraction of numbers
## 
## Implements the - operator. With one argument, returns negation.
## With multiple arguments, subtracts all subsequent values from the first.
## 
## Args:
##   args: Sequence of Node arguments for subtraction
## 
## Returns:
##   ParseResult containing the difference as a number Node or error
proc evaluateSubtraction(args: seq[Node]): ParseResult[Node] =
    if args.len == 0:
        return err[Node]("Subtraction requires at least one argument")

    # Evaluate first argument
    let firstResult = evaluate(args[0])
    if not firstResult.isOk:
        return firstResult

    let firstArg = firstResult.value
    if firstArg.kind != nkNumber:
        return err[Node]("Subtraction requires numeric arguments")

    # If only one argument, return negation
    if args.len == 1:
        return ok(newNumber(-firstArg.numberValue))

    # Subtract remaining arguments from first
    var result = firstArg.numberValue
    for i in 1..<args.len:
        let evalResult = evaluate(args[i])
        if not evalResult.isOk:
            return evalResult

        let evaluatedArg = evalResult.value
        if evaluatedArg.kind != nkNumber:
            return err[Node]("Subtraction requires numeric arguments")

        result -= evaluatedArg.numberValue

    return ok(newNumber(result))

## Evaluates multiplication of multiple numbers
## 
## Implements the * operator for multiplying numeric values.
## All arguments must be numbers.
## 
## Args:
##   args: Sequence of Node arguments to multiply
## 
## Returns:
##   ParseResult containing the product as a number Node or error
proc evaluateMultiplication(args: seq[Node]): ParseResult[Node] =
    if args.len == 0:
        return ok(newNumber(1))

    var product = 1
    for arg in args:
        let evalResult = evaluate(arg)
        if not evalResult.isOk:
            return evalResult

        let evaluatedArg = evalResult.value
        if evaluatedArg.kind != nkNumber:
            return err[Node]("Multiplication requires numeric arguments")

        product *= evaluatedArg.numberValue

    return ok(newNumber(product))

## Evaluates division of numbers
## 
## Implements the / operator. Divides the first argument by all subsequent arguments.
## Returns error on division by zero.
## 
## Args:
##   args: Sequence of Node arguments for division
## 
## Returns:
##   ParseResult containing the quotient as a number Node or error
proc evaluateDivision(args: seq[Node]): ParseResult[Node] =
    if args.len == 0:
        return err[Node]("Division requires at least one argument")

    # Evaluate first argument
    let firstResult = evaluate(args[0])
    if not firstResult.isOk:
        return firstResult

    let firstArg = firstResult.value
    if firstArg.kind != nkNumber:
        return err[Node]("Division requires numeric arguments")

    # If only one argument, return 1/x
    if args.len == 1:
        if firstArg.numberValue == 0:
            return err[Node]("Division by zero")
        return ok(newNumber(1 div firstArg.numberValue))

    # Divide first argument by remaining arguments
    var result = firstArg.numberValue
    for i in 1..<args.len:
        let evalResult = evaluate(args[i])
        if not evalResult.isOk:
            return evalResult

        let evaluatedArg = evalResult.value
        if evaluatedArg.kind != nkNumber:
            return err[Node]("Division requires numeric arguments")

        if evaluatedArg.numberValue == 0:
            return err[Node]("Division by zero")

        result = result div evaluatedArg.numberValue

    return ok(newNumber(result))