// name: FuncBuiltinEdge2
// keywords: edge
// status: correct
// cflags: -d=newInst
//
// Tests the builtin edge operator.
//

model FuncBuiltinEdge2
  Boolean b[3];
  Boolean x[:] = edge(b);
end FuncBuiltinEdge2;

// Result:
// class FuncBuiltinEdge2
//   Boolean b[1];
//   Boolean b[2];
//   Boolean b[3];
//   Boolean x[1];
//   Boolean x[2];
//   Boolean x[3];
// equation
//   x = array(edge(b[$i1]) for $i1 in 1:3);
// end FuncBuiltinEdge2;
// endResult
