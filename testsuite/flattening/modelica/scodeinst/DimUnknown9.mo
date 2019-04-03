// name: DimUnknown9
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model DimUnknown9
  parameter Integer n = 3;
  Real x[:] = {i for i in 1:n};
end DimUnknown9;

// Result:
// class DimUnknown9
//   parameter Integer n = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = /*Real[3]*/(array(i for i in 1:3));
// end DimUnknown9;
// endResult
