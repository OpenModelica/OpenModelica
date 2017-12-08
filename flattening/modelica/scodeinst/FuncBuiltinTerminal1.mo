// name: FuncBuiltinTerminal1
// keywords: terminal
// status: correct
// cflags: -d=newInst
//
// Tests the builtin terminal operator.
//

model FuncBuiltinTerminal1
  Boolean b = terminal();
end FuncBuiltinTerminal1;

// Result:
// class FuncBuiltinTerminal1
//   Boolean b = terminal();
// end FuncBuiltinTerminal1;
// endResult
