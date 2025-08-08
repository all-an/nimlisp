discard """
  action: "run"
  exitcode: 0
"""

import ../src/evaluator
import ../src/ast
import ../src/parser

block:
    let node = newNumber(42)
    let result = evaluate(node)
    assert result.isOk
    assert result.value.kind == nkNumber
    assert result.value.numberValue == 42

block:
    let node = newString("hello")
    let result = evaluate(node)
    assert result.isOk
    assert result.value.kind == nkString
    assert result.value.stringValue == "hello"

block:
    let node = newBool(true)
    let result = evaluate(node)
    assert result.isOk
    assert result.value.kind == nkBool
    assert result.value.boolValue == true

block:
    let elements = @[newSymbol("-"), newNumber(10), newNumber(3)]
    let node = newList(elements)
    let result = evaluate(node)
    assert result.isOk
    assert result.value.kind == nkNumber
    assert result.value.numberValue == 7

echo "Evaluator tests passed!"