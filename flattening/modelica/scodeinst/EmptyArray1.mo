// name: EmptyArray1
// keywords:
// status: correct
// cflags: -d=newInst
//

model EmptyArray1
  Real x[0];
equation
  x = ones(size(x, 1));
end EmptyArray1;

// Result:
// class EmptyArray1
// end EmptyArray1;
// endResult
