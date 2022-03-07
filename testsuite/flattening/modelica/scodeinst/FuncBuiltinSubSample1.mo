// name: FuncBuiltinSubSample1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinSubSample1
  Boolean b1;
  Boolean b2 = subSample(b1, 2);
end FuncBuiltinSubSample1;

// Result:
// class FuncBuiltinSubSample1
//   Boolean b1;
//   Boolean b2 = subSample(b1, 2);
// end FuncBuiltinSubSample1;
// endResult
