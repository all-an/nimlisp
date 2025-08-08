## AST (Abstract Syntax Tree) module for NimLisp
## 
## This module defines the node types and structures that represent
## the parsed structure of NimLisp programs. The AST is the core
## data structure for the homoiconic representation where code is data.

type
    ## Enumeration of all AST node kinds in NimLisp
    ## These represent the fundamental data types and structures
    NodeKind* = enum
        nkNumber    ## Integer or floating-point number literal
        nkString    ## String literal value
        nkBool      ## Boolean value (#t or #f)
        nkSymbol    ## Symbol (identifier) for variables and functions
        nkList      ## S-expression list (can represent code or data)
        nkQuote     ## Quoted expression (literal data)

    ## AST Node represents any syntactic element in NimLisp
    ## This is the core homoiconic data structure where code and data
    ## share the same representation as nested nodes
    Node* = ref object
        case kind*: NodeKind
        of nkNumber:
            numberValue*: int         ## The numeric value for number nodes
        of nkString:
            stringValue*: string      ## The string content for string nodes
        of nkBool:
            boolValue*: bool          ## The boolean value for bool nodes
        of nkSymbol:
            symbolName*: string       ## The symbol name for symbol nodes
        of nkList:
            elements*: seq[Node]      ## The child nodes for list nodes
        of nkQuote:
            quoted*: Node             ## The quoted expression

## Creates a new number node with the specified integer value
## 
## Args:
##   value: The integer value to store in the node
## 
## Returns:
##   A new Node of kind nkNumber containing the value
proc newNumber*(value: int): Node =
    Node(kind: nkNumber, numberValue: value)

## Creates a new string node with the specified string content
## 
## Args:
##   value: The string content to store in the node
## 
## Returns:
##   A new Node of kind nkString containing the string value
proc newString*(value: string): Node =
    Node(kind: nkString, stringValue: value)

## Creates a new boolean node with the specified boolean value
## 
## Args:
##   value: The boolean value to store in the node
## 
## Returns:
##   A new Node of kind nkBool containing the boolean value
proc newBool*(value: bool): Node =
    Node(kind: nkBool, boolValue: value)

## Creates a new symbol node with the specified name
## 
## Symbols represent identifiers for variables, functions, and operators
## in the NimLisp language.
## 
## Args:
##   name: The symbol name/identifier string
## 
## Returns:
##   A new Node of kind nkSymbol containing the symbol name
proc newSymbol*(name: string): Node =
    Node(kind: nkSymbol, symbolName: name)

## Creates a new list node with the specified child elements
## 
## Lists are the fundamental structure of S-expressions and represent
## both code (function calls) and data (collections) in NimLisp.
## 
## Args:
##   elements: A sequence of Node objects to be the list elements
## 
## Returns:
##   A new Node of kind nkList containing the elements
proc newList*(elements: seq[Node]): Node =
    Node(kind: nkList, elements: elements)

## Creates a new quote node that holds a quoted expression
## 
## Quote nodes represent literal data that should not be evaluated,
## supporting the homoiconic nature of the language.
## 
## Args:
##   quoted: The Node to be quoted (treated as literal data)
## 
## Returns:
##   A new Node of kind nkQuote containing the quoted expression
proc newQuote*(quoted: Node): Node =
    Node(kind: nkQuote, quoted: quoted)

## Converts an AST node to its string representation
## 
## This provides the canonical textual representation of any node,
## supporting the homoiconic principle where code and data have
## identical string representations.
## 
## Args:
##   node: The Node to convert to string representation
## 
## Returns:
##   A string representation of the node and its structure
proc `$`*(node: Node): string =
    case node.kind
    of nkNumber:
        result = $node.numberValue
    of nkString:
        result = "\"" & node.stringValue & "\""
    of nkBool:
        result = if node.boolValue: "#t" else: "#f"
    of nkSymbol:
        result = node.symbolName
    of nkList:
        if node.elements.len == 0:
            result = "()"
        else:
            result = "("
            for i, element in node.elements:
                if i > 0:
                    result.add(" ")
                result.add($element)
            result.add(")")
    of nkQuote:
        result = "'" & $node.quoted