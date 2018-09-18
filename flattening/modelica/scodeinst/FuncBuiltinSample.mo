// name: FuncBuiltinSample
// keywords: sample
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sample operator.
//

model FuncBuiltinSample
  Boolean b = sample(1.0, 2);
  Boolean c = sample(1, 2);
  Boolean d = sample(1, 2.0);
end FuncBuiltinSample;

// Result:
// class FuncBuiltinSample
//   Boolean b = sample(1.0, 2.0);
//   Boolean c = sample(1.0, 2.0);
//   Boolean d = sample(1.0, 2.0);
// end FuncBuiltinSample;
// endResult
