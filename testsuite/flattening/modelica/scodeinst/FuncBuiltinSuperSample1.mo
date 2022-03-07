// name: FuncBuiltinSuperSample1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinSuperSample1
  Boolean b1;
  Boolean b2 = superSample(b1, 2);
end FuncBuiltinSuperSample1;

// Result:
// class FuncBuiltinSuperSample1
//   Boolean b1;
//   Boolean b2 = superSample(b1, 2);
// end FuncBuiltinSuperSample1;
// endResult
