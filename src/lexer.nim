## Lexer module for NimLisp tokenization
## 
## This module implements a lexical analyzer that converts NimLisp source code
## into a sequence of tokens. It handles S-expression syntax, strings, numbers,
## symbols, and special operators while tracking position for error reporting.

import token
import strutils

type
    ## Lexer performs tokenization of NimLisp source code
    ## Maintains position information and handles all token types
    Lexer* = object
        source: string      ## The complete source code being tokenized
        tokens: seq[Token]  ## Accumulated tokens from tokenization
        start: int          ## Start position of current token being scanned
        current: int        ## Current character position in source
        line: int           ## Current line number (1-based)
        column: int         ## Current column position (1-based)

## Creates a new Lexer for the given source code
## 
## Initializes the lexer state with position tracking starting at
## line 1, column 1 as per standard text editor conventions.
## 
## Args:
##   source: The complete NimLisp source code to tokenize
## 
## Returns:
##   A new Lexer ready to tokenize the source
proc newLexer*(source: string): Lexer =
    Lexer(
        source: source,
        tokens: @[],
        start: 0,
        current: 0,
        line: 1,
        column: 1
    )

## Checks if the lexer has reached the end of source
## 
## Returns:
##   true if no more characters to process, false otherwise
proc isAtEnd(lexer: Lexer): bool =
    lexer.current >= lexer.source.len

## Advances to the next character and returns the current one
## 
## Updates both the current position and column tracking.
## Handles newlines by incrementing line count and resetting column.
## 
## Returns:
##   The character at the current position before advancing
proc advance(lexer: var Lexer): char =
    result = lexer.source[lexer.current]
    lexer.current += 1
    if result == '\n':
        lexer.line += 1
        lexer.column = 1
    else:
        lexer.column += 1

## Peeks at the current character without advancing
## 
## Returns:
##   The current character, or '\0' if at end of source
proc peek(lexer: Lexer): char =
    if lexer.isAtEnd(): '\0'
    else: lexer.source[lexer.current]

## Peeks at the next character without advancing
## 
## Returns:
##   The character after current position, or '\0' if not available
proc peekNext(lexer: Lexer): char =
    if lexer.current + 1 >= lexer.source.len: '\0'
    else: lexer.source[lexer.current + 1]

## Adds a token with the specified kind to the tokens sequence
## 
## Uses the current lexer position for line/column information
## and extracts lexeme from the source between start and current positions.
## 
## Args:
##   kind: The TokenKind to add
proc addToken(lexer: var Lexer, kind: TokenKind) =
    let lexeme = lexer.source[lexer.start..<lexer.current]
    let token = newToken(kind, lexeme, lexer.line, lexer.column - lexeme.len)
    lexer.tokens.add(token)

## Adds a token with a custom lexeme (for processed strings)
## 
## Used when the token's lexeme differs from the raw source text,
## such as for string literals where quotes are stripped.
## 
## Args:
##   kind: The TokenKind to add
##   lexeme: The processed lexeme text
proc addTokenWithLexeme(lexer: var Lexer, kind: TokenKind, lexeme: string) =
    let token = newToken(kind, lexeme, lexer.line, lexer.column - (lexer.current - lexer.start))
    lexer.tokens.add(token)

## Skips whitespace characters without creating tokens
## 
## Advances through spaces, tabs, carriage returns, and newlines
## while maintaining proper position tracking.
proc skipWhitespace(lexer: var Lexer) =
    while not lexer.isAtEnd():
        case lexer.peek()
        of ' ', '\t', '\r', '\n':
            discard lexer.advance()
        else:
            break

## Tokenizes a string literal enclosed in double quotes
## 
## Handles string escaping and advances through the entire string.
## Reports error if string is unterminated.
proc tokenizeString(lexer: var Lexer) =
    var value = ""

    while not lexer.isAtEnd() and lexer.peek() != '"':
        if lexer.peek() == '\\':
            discard lexer.advance()
            if not lexer.isAtEnd():
                case lexer.peek()
                of 'n': value.add('\n')
                of 't': value.add('\t')
                of 'r': value.add('\r')
                of '\\': value.add('\\')
                of '"': value.add('"')
                else: value.add(lexer.peek())
                discard lexer.advance()
        else:
            value.add(lexer.advance())

    if lexer.isAtEnd():
        lexer.addToken(tkError)
        return

    discard lexer.advance()  # Consume closing "
    lexer.addTokenWithLexeme(tkString, value)

## Tokenizes a number (integer or floating-point)
## 
## Handles negative numbers and basic numeric formats.
## Does not perform full numeric validation.
proc tokenizeNumber(lexer: var Lexer) =
    while not lexer.isAtEnd() and lexer.peek().isDigit():
        discard lexer.advance()

    if not lexer.isAtEnd() and lexer.peek() == '.' and lexer.peekNext().isDigit():
        discard lexer.advance()  # Consume '.'
        while not lexer.isAtEnd() and lexer.peek().isDigit():
            discard lexer.advance()

    lexer.addToken(tkNumber)

## Checks if a character can start a symbol
## 
## Args:
##   c: Character to check
## 
## Returns:
##   true if character can begin a symbol
proc canStartSymbol(c: char): bool =
    c.isAlphaAscii() or c in "+-*/%=<>!?_"

## Checks if a character can appear in a symbol
## 
## Args:
##   c: Character to check
## 
## Returns:
##   true if character can appear in symbol
proc canContinueSymbol(c: char): bool =
    c.canStartSymbol() or c.isDigit()

## Tokenizes a symbol (identifier)
## 
## Advances through all valid symbol characters and creates
## a symbol token from the accumulated text.
proc tokenizeSymbol(lexer: var Lexer) =
    while not lexer.isAtEnd() and lexer.peek().canContinueSymbol():
        discard lexer.advance()

    lexer.addToken(tkSymbol)

## Tokenizes a single character or multi-character token
## 
## Handles all single-character tokens and multi-character operators.
## Delegates to specialized tokenizers for complex tokens.
proc scanToken(lexer: var Lexer) =
    let c = lexer.advance()

    case c
    of '(': lexer.addToken(tkLeftParen)
    of ')': lexer.addToken(tkRightParen)
    of '\'': lexer.addToken(tkQuote)
    of '`': lexer.addToken(tkBackquote)
    of ',':
        if lexer.peek() == '@':
            discard lexer.advance()
            lexer.addToken(tkUnquoteSplice)
        else:
            lexer.addToken(tkUnquote)
    of '"': lexer.tokenizeString()
    of '#':
        if lexer.peek() == 't' or lexer.peek() == 'f':
            discard lexer.advance()
            lexer.addToken(tkBool)
        else:
            lexer.addToken(tkError)
    of '-':
        if not lexer.isAtEnd() and lexer.peek().isDigit():
            lexer.tokenizeNumber()
        else:
            lexer.tokenizeSymbol()
    else:
        if c.isDigit():
            lexer.tokenizeNumber()
        elif c.canStartSymbol():
            lexer.tokenizeSymbol()
        else:
            lexer.addToken(tkError)

## Tokenizes the entire source code into a sequence of tokens
## 
## Processes the source from start to finish, skipping whitespace
## and creating tokens for all recognized syntax elements.
## Always ends with an EOF token.
## 
## Returns:
##   A sequence of all tokens found in the source code
proc tokenize*(lexer: var Lexer): seq[Token] =
    while not lexer.isAtEnd():
        lexer.start = lexer.current
        lexer.skipWhitespace()

        if not lexer.isAtEnd():
            lexer.start = lexer.current
            lexer.scanToken()

    lexer.tokens.add(newToken(tkEof, "", lexer.line, lexer.column))
    return lexer.tokens