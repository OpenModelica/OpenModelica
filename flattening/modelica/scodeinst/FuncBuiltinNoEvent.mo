// name: FuncBuiltinNoEvent
// keywords: noEvent
// status: correct
// cflags: -d=newInst
//
// Tests the builtin noEvent operator.
//

model FuncBuiltinNoEvent
  Real x = time;
  Real y = noEvent(x);
end FuncBuiltinNoEvent;

// Result:
// class FuncBuiltinNoEvent
//   Real x = time;
//   Real y = noEvent(x);
// end FuncBuiltinNoEvent;
// endResult
