## Token module for NimLisp lexical analysis
## 
## This module defines the token types and structures used by the lexer
## to represent atomic elements of NimLisp source code.

type
    ## Enumeration of all possible token kinds in NimLisp
    ## Each token represents a basic syntactic element
    TokenKind* = enum
        tkLeftParen = "("           ## Opening parenthesis for S-expressions
        tkRightParen = ")"          ## Closing parenthesis for S-expressions  
        tkSymbol = "symbol"         ## Identifiers and function names
        tkNumber = "number"         ## Integer and floating-point literals
        tkString = "string"         ## String literals enclosed in quotes
        tkBool = "bool"             ## Boolean literals (#t, #f)
        tkQuote = "'"               ## Quote operator for literal data
        tkBackquote = "`"           ## Backquote for quasi-quotation
        tkUnquote = ","             ## Unquote operator in quasi-quotation
        tkUnquoteSplice = ",@"      ## Unquote-splice operator
        tkEof = "eof"               ## End of file marker
        tkError = "error"           ## Error token for invalid input

    ## Token represents a single lexical unit with position information
    ## Contains the token type, source text, and location for error reporting
    Token* = object
        kind*: TokenKind    ## The type classification of this token
        lexeme*: string     ## The actual source text that formed this token
        line*: int          ## Line number where this token appears (1-based)
        column*: int        ## Column position where this token starts (1-based)

## Creates a new Token with the specified properties
## 
## Args:
##   kind: The TokenKind classification
##   lexeme: The source text string
##   line: Line number (1-based)
##   column: Column position (1-based)
## 
## Returns:
##   A new Token object with the given properties
proc newToken*(kind: TokenKind, lexeme: string, line: int, column: int): Token =
    Token(kind: kind, lexeme: lexeme, line: line, column: column)

## Converts a Token to its string representation for debugging
## 
## The format includes the token kind, lexeme (if different from kind),
## and position information for debugging purposes.
## 
## Args:
##   token: The Token to convert to string
## 
## Returns:
##   A string representation of the token
proc `$`*(token: Token): string =
    result = "Token(" & $token.kind
    if token.lexeme != $token.kind:
        result &= ", \"" & token.lexeme & "\""
    result &= " at " & $token.line & ":" & $token.column & ")"