discard """
  action: "run"
  exitcode: 0
"""

import ../src/lexer
import ../src/token

block:
    var lexer = newLexer("")
    let tokens = lexer.tokenize()
    assert tokens.len == 1
    assert tokens[0].kind == tkEof

block:
    var lexer = newLexer("(")
    let tokens = lexer.tokenize()
    assert tokens.len == 2
    assert tokens[0].kind == tkLeftParen
    assert tokens[0].lexeme == "("

block:
    var lexer = newLexer("hello")
    let tokens = lexer.tokenize()
    assert tokens.len == 2
    assert tokens[0].kind == tkSymbol
    assert tokens[0].lexeme == "hello"

block:
    var lexer = newLexer("42")
    let tokens = lexer.tokenize()
    assert tokens.len == 2
    assert tokens[0].kind == tkNumber
    assert tokens[0].lexeme == "42"

echo "Lexer tests passed!"