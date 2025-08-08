discard """
  action: "run"
  exitcode: 0
"""

import ../src/parser
import ../src/ast

block:
    let result = parseExpression("42")
    assert result.isOk
    let node = result.value
    assert node.kind == nkNumber
    assert node.numberValue == 42

block:
    let result = parseExpression("\"hello\"")
    assert result.isOk
    let node = result.value
    assert node.kind == nkString
    assert node.stringValue == "hello"

block:
    let result = parseExpression("#t")
    assert result.isOk
    let node = result.value
    assert node.kind == nkBool
    assert node.boolValue == true

block:
    let result = parseExpression("(+ 1 2)")
    assert result.isOk
    let node = result.value
    assert node.kind == nkList
    assert node.elements.len == 3

echo "Parser tests passed!"