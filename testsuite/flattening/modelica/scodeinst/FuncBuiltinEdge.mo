// name: FuncBuiltinEdge
// keywords: edge
// status: correct
// cflags: -d=newInst
//
// Tests the builtin edge operator.
//

model FuncBuiltinEdge
  Boolean b1;
  Boolean b2 = edge(b1);
end FuncBuiltinEdge;

// Result:
// class FuncBuiltinEdge
//   Boolean b1;
//   Boolean b2 = edge(b1);
// end FuncBuiltinEdge;
// endResult
