// name: DimUnknown6
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x[:];
end A;

model DimUnknown6
  A a(x = {1, 2, 3});
end DimUnknown6;

// Result:
// class DimUnknown6
//   Real a.x[1];
//   Real a.x[2];
//   Real a.x[3];
// equation
//   a.x = {1.0, 2.0, 3.0};
// end DimUnknown6;
// endResult
