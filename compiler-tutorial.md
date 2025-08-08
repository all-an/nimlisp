# Compiler Tutorial: Lexer, Parser, and AST Explained

This tutorial explains the three fundamental components of a compiler frontend in simple terms, using examples from our NimLisp language.

## The Big Picture

When you write code and run a compiler, your source code goes through several transformation stages:

```
Source Code → Lexer → Parser → AST → Code Generator → Machine Code
```

Think of it like cooking:
- **Lexer**: Chops ingredients (breaks text into tokens)
- **Parser**: Follows recipe structure (arranges tokens into meaningful groups)
- **AST**: The organized recipe (structured representation of your program)

## 1. Lexer (Tokenizer)

### What is a Lexer?

A lexer is like a smart text scanner. It reads your source code character by character and groups them into **tokens** - the basic building blocks of your programming language.

### Example: Breaking Down Code

Let's say you write this NimLisp code:
```lisp
(+ 42 "hello")
```

The lexer breaks this down into tokens:

```
Input:  (+ 42 "hello")

Tokens: 
1. LEFT_PAREN: '('
2. SYMBOL:     '+'
3. NUMBER:     '42'
4. STRING:     '"hello"'
5. RIGHT_PAREN: ')'
```

### What the Lexer Does

1. **Recognizes patterns**: Is `42` a number? Is `"hello"` a string?
2. **Ignores whitespace**: Spaces and tabs usually don't matter
3. **Handles special characters**: Parentheses, quotes, operators
4. **Reports errors**: "Unknown character '%' at line 5"

### Lexer Implementation Example

```nim
# Simple token types
type TokenType = enum
    LEFT_PAREN, RIGHT_PAREN
    SYMBOL, NUMBER, STRING
    EOF

type Token = object
    tokenType: TokenType
    value: string
    line: int
    column: int

# Lexer function (simplified)
proc nextToken(lexer: var Lexer): Token =
    skipWhitespace(lexer)
    
    case lexer.currentChar:
    of '(':
        return Token(tokenType: LEFT_PAREN, value: "(")
    of ')':
        return Token(tokenType: RIGHT_PAREN, value: ")")
    of '"':
        return readString(lexer)  # Reads until closing quote
    of '0'..'9':
        return readNumber(lexer)  # Reads digits
    else:
        return readSymbol(lexer)  # Reads letters/symbols
```

## 2. Parser

### What is a Parser?

A parser takes the flat list of tokens from the lexer and organizes them into a **tree structure** that represents the meaning and structure of your code.

### Example: From Tokens to Structure

Taking our tokens from before:
```
Tokens: LEFT_PAREN, SYMBOL(+), NUMBER(42), STRING("hello"), RIGHT_PAREN
```

The parser recognizes this as a **function call** and creates this structure:
```
Function Call:
├── Function: +
├── Argument 1: 42
└── Argument 2: "hello"
```

### What the Parser Does

1. **Recognizes grammar**: "This looks like a function call"
2. **Checks syntax**: "Missing closing parenthesis!"
3. **Creates hierarchy**: Functions have arguments, blocks have statements
4. **Reports structure errors**: "Expected expression after '+'"

### Parser Implementation Example

```nim
# Parse a function call: (function arg1 arg2 ...)
proc parseFunctionCall(parser: var Parser): AstNode =
    expect(LEFT_PAREN)  # Must start with '('
    
    let functionName = expect(SYMBOL)  # Function name
    var arguments: seq[AstNode] = @[]
    
    # Parse arguments until we hit ')'
    while parser.currentToken.tokenType != RIGHT_PAREN:
        arguments.add(parseExpression(parser))
    
    expect(RIGHT_PAREN)  # Must end with ')'
    
    return AstNode(
        nodeType: FUNCTION_CALL,
        functionName: functionName.value,
        arguments: arguments
    )
```

## 3. AST (Abstract Syntax Tree)

### What is an AST?

An AST is like a family tree for your code. It shows how different parts of your program relate to each other in a structured, hierarchical way.

### Example: Visualizing the Tree

Our expression `(+ 42 "hello")` becomes this AST:

```
      FunctionCall
      /     |     \
   name   arg1   arg2
    |      |      |
   "+"    42   "hello"
```

Or in a more detailed view:
```nim
AstNode(
  nodeType: FUNCTION_CALL,
  functionName: "+",
  arguments: [
    AstNode(nodeType: NUMBER, value: "42"),
    AstNode(nodeType: STRING, value: "hello")
  ]
)
```

### What the AST Represents

1. **Structure**: How expressions nest inside each other
2. **Meaning**: This is a function call, not just random symbols
3. **Relationships**: Which arguments belong to which function
4. **Type information**: This is a number, that's a string

### AST Implementation Example

```nim
type NodeType = enum
    FUNCTION_CALL, NUMBER, STRING, SYMBOL, LIST

type AstNode = object
    nodeType: NodeType
    case nodeType:
    of FUNCTION_CALL:
        functionName: string
        arguments: seq[AstNode]
    of NUMBER:
        numberValue: float
    of STRING:
        stringValue: string
    of SYMBOL:
        symbolName: string
    of LIST:
        elements: seq[AstNode]

# Pretty printing the AST
proc print(node: AstNode, indent: int = 0) =
    let spaces = "  ".repeat(indent)
    case node.nodeType:
    of FUNCTION_CALL:
        echo spaces & "FunctionCall: " & node.functionName
        for arg in node.arguments:
            print(arg, indent + 1)
    of NUMBER:
        echo spaces & "Number: " & $node.numberValue
    of STRING:
        echo spaces & "String: " & node.stringValue
```

## Complete Example: Pipeline in Action

Let's trace through a more complex example:

### Source Code
```lisp
(if (> x 10) 
    "big" 
    "small")
```

### Step 1: Lexer Output
```
LEFT_PAREN, SYMBOL(if), LEFT_PAREN, SYMBOL(>), SYMBOL(x), 
NUMBER(10), RIGHT_PAREN, STRING("big"), STRING("small"), RIGHT_PAREN
```

### Step 2: Parser Output (AST)
```
      IfExpression
     /      |       \
condition  then    else
    |       |       |
    >     "big"  "small"
   / \
  x   10
```

### Step 3: AST Structure
```nim
AstNode(
  nodeType: IF_EXPRESSION,
  condition: AstNode(
    nodeType: FUNCTION_CALL,
    functionName: ">",
    arguments: [
      AstNode(nodeType: SYMBOL, symbolName: "x"),
      AstNode(nodeType: NUMBER, numberValue: 10.0)
    ]
  ),
  thenBranch: AstNode(nodeType: STRING, stringValue: "big"),
  elseBranch: AstNode(nodeType: STRING, stringValue: "small")
)
```

## Key Takeaways

1. **Lexer**: Converts text into tokens (words)
2. **Parser**: Arranges tokens into meaningful structures
3. **AST**: Tree representation that captures program structure

Each step builds on the previous one:
- Lexer handles the **what** (what are these characters?)
- Parser handles the **how** (how do these tokens fit together?)
- AST handles the **meaning** (what does this structure represent?)

This pipeline is the foundation of every compiler and interpreter. Once you have an AST, you can analyze it, optimize it, type-check it, or generate code from it.