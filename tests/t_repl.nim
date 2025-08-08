discard """
  action: "run"
  exitcode: 0
"""

import strutils
import ../src/repl

block:
    let result = evalExpression("42")
    assert result.contains("42")

block:
    let result = evalExpression("\"hello\"")
    assert result.contains("\"hello\"")

block:
    let result = evalExpression("#t")
    assert result.contains("#t")

block:
    let result = evalExpression("(+ 1 2)")
    assert result.contains("3")

echo "REPL tests passed!"