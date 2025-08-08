discard """
  action: "run"
  exitcode: 0
"""

import ../src/ast

block:
    let node = newNumber(42)
    assert node.kind == nkNumber
    assert node.numberValue == 42

block:
    let node = newString("hello")
    assert node.kind == nkString
    assert node.stringValue == "hello"

block:
    let node = newBool(true)
    assert node.kind == nkBool
    assert node.boolValue == true

block:
    let node = newSymbol("test")
    assert node.kind == nkSymbol
    assert node.symbolName == "test"

block:
    let elements = @[newSymbol("+"), newNumber(1), newNumber(2)]
    let node = newList(elements)
    assert node.kind == nkList
    assert node.elements.len == 3

echo "AST tests passed!"