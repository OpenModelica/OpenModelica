// name: DimUnknown11
// keywords:
// status: correct
//
//

model A
  Real [:, 2] x;
end A;

model DimUnknown11
  A a(x(start = {{1, 1}, {1, 1}, {1, 1}}));
end DimUnknown11;

// Result:
// class DimUnknown11
//   Real a.x[1,1](start = 1.0);
//   Real a.x[1,2](start = 1.0);
//   Real a.x[2,1](start = 1.0);
//   Real a.x[2,2](start = 1.0);
//   Real a.x[3,1](start = 1.0);
//   Real a.x[3,2](start = 1.0);
// end DimUnknown11;
// endResult
