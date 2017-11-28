// name: FuncBuiltinSample
// keywords: sample
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sample operator.
//

model FuncBuiltinSample
  Boolean b = sample(1.0, 2);
end FuncBuiltinSample;

// Result:
// class FuncBuiltinSample
//   Boolean b = sample(1.0, 2.0);
// end FuncBuiltinSample;
// endResult
