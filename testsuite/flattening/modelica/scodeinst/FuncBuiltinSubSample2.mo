// name: FuncBuiltinSubSample2
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinSubSample2
  Clock c1 = Clock(1);
  Clock c2 = subSample(c1, 2);
end FuncBuiltinSubSample2;

// Result:
// class FuncBuiltinSubSample2
//   Clock c1 = Clock(1, 1);
//   Clock c2 = subSample(c1, 2);
// end FuncBuiltinSubSample2;
// endResult
