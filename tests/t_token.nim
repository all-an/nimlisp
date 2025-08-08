discard """
  action: "run"
  exitcode: 0
"""

import ../src/token

block:
    let token = newToken(tkSymbol, "hello", 1, 5)
    assert token.kind == tkSymbol
    assert token.lexeme == "hello"
    assert token.line == 1
    assert token.column == 5

echo "Token tests passed!"