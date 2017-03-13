// name: FuncBuiltinTerminal
// keywords: terminal
// status: correct
// cflags: -d=newInst
//
// Tests the builtin terminal operator.
//

model FuncBuiltinTerminal
  Boolean s = terminal();
end FuncBuiltinTerminal;

// Result:
// class FuncBuiltinTerminal
//   Boolean s = terminal();
// end FuncBuiltinTerminal;
// endResult
