// name: FuncBuiltinBackSample1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinBackSample1
  Clock c1 = Clock(3, 10);
  Clock c2 = backSample(c1, 2);
end FuncBuiltinBackSample1;

// Result:
// class FuncBuiltinBackSample1
//   Clock c1 = Clock(3, 10);
//   Clock c2 = backSample(c1, 2, 1);
// end FuncBuiltinBackSample1;
// endResult
