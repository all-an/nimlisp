## Main executable for NimLisp interpreter
## 
## This is the entry point for the NimLisp language interpreter.
## It starts the REPL (Read-Eval-Print Loop) for interactive use.

import repl

## Main entry point for NimLisp interpreter
## 
## Starts the interactive REPL session where users can enter
## NimLisp expressions and see their evaluated results.
when isMainModule:
    startRepl()