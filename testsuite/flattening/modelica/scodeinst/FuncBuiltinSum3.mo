// name: FuncBuiltinSum3
// keywords: sum
// status: correct
//
// Tests the builtin sum operator.
//

model FuncBuiltinSum3
  Real x[0];
  Real y = sum(x);
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end FuncBuiltinSum3;

// Result:
// class FuncBuiltinSum3
//   Real y = 0.0;
// end FuncBuiltinSum3;
// endResult
