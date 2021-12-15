// name: FuncBuiltinShiftSample1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinShiftSample1
  Clock c1 = Clock(3, 10);
  Clock c2 = shiftSample(c1, 1, 3);
end FuncBuiltinShiftSample1;

// Result:
// class FuncBuiltinShiftSample1
//   Clock c1 = Clock(3, 10);
//   Clock c2 = shiftSample(c1, 1, 3);
// end FuncBuiltinShiftSample1;
// endResult
