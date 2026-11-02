// name: FuncBuiltinEdge
// keywords: edge
// status: correct
//
// Tests the builtin edge operator.
//

model FuncBuiltinEdge
  Boolean b1;
  Boolean b2 = edge(b1);
  constant Boolean b3 = true;
  Boolean b4 = edge(b3);
end FuncBuiltinEdge;

// Result:
// class FuncBuiltinEdge
//   Boolean b1;
//   Boolean b2 = edge(b1);
//   constant Boolean b3 = true;
//   Boolean b4 = false;
// end FuncBuiltinEdge;
// endResult
