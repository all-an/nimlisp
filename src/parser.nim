## Parser module for NimLisp S-expression parsing
## 
## This module implements a recursive descent parser that converts
## sequences of tokens into Abstract Syntax Tree (AST) nodes.
## It handles the homoiconic S-expression syntax of NimLisp.

import token
import lexer
import ast
import strutils

type
    ## Result type for parse operations that can succeed or fail
    ## Provides error handling for parse failures with descriptive messages
    ParseResult*[T] = object
        case isOk*: bool
        of true:
            value*: T           ## The successfully parsed value
        of false:
            error*: string      ## Error message describing parse failure

## Helper to check if a ParseResult represents an error
## 
## Returns:
##   true if the result represents a failure, false otherwise
proc isErr*[T](parseResult: ParseResult[T]): bool = not parseResult.isOk

type
    ## Parser maintains state during recursive descent parsing
    ## Tracks current position in token sequence and provides error context
    Parser = object
        tokens: seq[Token]    ## The sequence of tokens to parse
        current: int          ## Current position in the token sequence

## Creates a successful ParseResult containing a value
## 
## Args:
##   value: The successfully parsed value to wrap
## 
## Returns:
##   A ParseResult indicating success with the given value
proc ok*[T](value: T): ParseResult[T] =
    ParseResult[T](isOk: true, value: value)

## Creates a failed ParseResult containing an error message
## 
## Args:
##   error: Descriptive error message explaining the parse failure
## 
## Returns:
##   A ParseResult indicating failure with the error message
proc err*[T](error: string): ParseResult[T] =
    ParseResult[T](isOk: false, error: error)

## Creates a new Parser for the given token sequence
## 
## Args:
##   tokens: The sequence of tokens to parse
## 
## Returns:
##   A new Parser initialized to parse the token sequence
proc newParser(tokens: seq[Token]): Parser =
    Parser(tokens: tokens, current: 0)

## Checks if the parser has reached the end of tokens
## 
## Returns:
##   true if no more tokens to parse, false otherwise
proc isAtEnd(parser: Parser): bool =
    parser.current >= parser.tokens.len or 
    parser.tokens[parser.current].kind == tkEof

## Returns the current token without advancing
## 
## Returns:
##   The Token at the current parser position
proc peek(parser: Parser): Token =
    if parser.isAtEnd():
        Token(kind: tkEof, lexeme: "", line: 0, column: 0)
    else:
        parser.tokens[parser.current]

## Returns the previous token (assumes current > 0)
## 
## Returns:
##   The Token at the previous parser position
proc previous(parser: Parser): Token =
    parser.tokens[parser.current - 1]

## Advances to the next token and returns the current one
## 
## Returns:
##   The Token at the current position before advancing
proc advance(parser: var Parser): Token =
    if not parser.isAtEnd():
        parser.current += 1
    return parser.previous()

## Checks if the current token matches any of the given kinds
## 
## Args:
##   kinds: Variable number of TokenKind values to check against
## 
## Returns:
##   true if current token matches any of the given kinds
proc match(parser: Parser, kinds: varargs[TokenKind]): bool =
    for kind in kinds:
        if parser.peek().kind == kind:
            return true
    return false

## Consumes a token of the expected kind or returns error
## 
## Args:
##   kind: The expected TokenKind to consume
##   message: Error message if token doesn't match expectation
## 
## Returns:
##   ParseResult indicating success or failure of token consumption
proc consume(parser: var Parser, kind: TokenKind, message: string): ParseResult[Token] =
    if parser.peek().kind == kind:
        return ok(parser.advance())
    else:
        let current = parser.peek()
        return err[Token](message & " at line " & $current.line & ":" & $current.column)

## Forward declaration for mutual recursion
proc parseExpression(parser: var Parser): ParseResult[Node]

## Parses a primary expression (atomic values and parenthesized expressions)
## 
## Handles numbers, strings, booleans, symbols, lists, and quotes.
## This is the lowest level of the recursive descent parser.
## 
## Returns:
##   ParseResult containing the parsed Node or error message
proc parsePrimary(parser: var Parser): ParseResult[Node] =
    let token = parser.peek()

    case token.kind
    of tkNumber:
        discard parser.advance()
        try:
            let value = parseInt(token.lexeme)
            return ok(newNumber(value))
        except ValueError:
            return err[Node]("Invalid number format: " & token.lexeme)

    of tkString:
        discard parser.advance()
        return ok(newString(token.lexeme))

    of tkBool:
        discard parser.advance()
        let value = token.lexeme == "#t"
        return ok(newBool(value))

    of tkSymbol:
        discard parser.advance()
        return ok(newSymbol(token.lexeme))

    of tkLeftParen:
        discard parser.advance()
        var elements: seq[Node] = @[]

        while not parser.match(tkRightParen) and not parser.isAtEnd():
            let elementResult = parser.parseExpression()
            if not elementResult.isOk:
                return err[Node](elementResult.error)
            elements.add(elementResult.value)

        let closeResult = parser.consume(tkRightParen, "Expected ')' after list elements")
        if not closeResult.isOk:
            return err[Node](closeResult.error)

        return ok(newList(elements))

    of tkQuote:
        discard parser.advance()
        let quotedResult = parser.parseExpression()
        if not quotedResult.isOk:
            return err[Node](quotedResult.error)
        return ok(newQuote(quotedResult.value))

    of tkEof:
        return err[Node]("Unexpected end of input")

    else:
        return err[Node]("Unexpected token: " & token.lexeme & " at line " & $token.line & ":" & $token.column)

## Parses a complete expression
## 
## Currently delegates to parsePrimary but provides extension point
## for future operator precedence and other expression constructs.
## 
## Returns:
##   ParseResult containing the parsed Node or error message
proc parseExpression(parser: var Parser): ParseResult[Node] =
    return parser.parsePrimary()

## Parses a single NimLisp expression from source code string
## 
## This is the main entry point for parsing. It tokenizes the source,
## parses a single expression, and ensures no extra tokens remain.
## 
## Args:
##   source: The NimLisp source code string to parse
## 
## Returns:
##   ParseResult containing the parsed AST Node or error message
proc parseExpression*(source: string): ParseResult[Node] =
    if source.strip() == "":
        return err[Node]("Empty input")

    var lexer = newLexer(source)
    let tokens = lexer.tokenize()

    # Check for lexer errors
    for token in tokens:
        if token.kind == tkError:
            return err[Node]("Lexer error at line " & $token.line & ":" & $token.column)

    var parser = newParser(tokens)
    let parseResult = parser.parseExpression()

    if not parseResult.isOk:
        return parseResult

    # Check for extra tokens after the expression
    if not parser.match(tkEof):
        let extra = parser.peek()
        return err[Node]("Unexpected token after expression: " & extra.lexeme & " at line " & $extra.line & ":" & $extra.column)

    return parseResult