// name: DimUnknown15
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x[:] = {1, 2, 3};
  output Real y[:] = x;
end f;

model DimUnknown15
  Real x[:] = f({1, 2, 3, 4});
end DimUnknown15;

// Result:
// class DimUnknown15
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
// equation
//   x = {1.0, 2.0, 3.0, 4.0};
// end DimUnknown15;
// endResult
