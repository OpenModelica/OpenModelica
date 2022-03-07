// name: FuncBuiltinSuperSample2
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinSuperSample2
  Clock c1 = Clock(1);
  Clock c2 = superSample(c1, 2);
end FuncBuiltinSuperSample2;

// Result:
// class FuncBuiltinSuperSample2
//   Clock c1 = Clock(1, 1);
//   Clock c2 = superSample(c1, 2);
// end FuncBuiltinSuperSample2;
// endResult
