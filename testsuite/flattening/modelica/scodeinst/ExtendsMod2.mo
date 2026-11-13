// name: ExtendsMod2
// keywords:
// status: correct
//
//

model A
  Real x;
end A;

model B = A(x = 1.0);

model C
  extends B;
end C;

model ExtendsMod2
  C c;
end ExtendsMod2;

// Result:
// class ExtendsMod2
//   Real c.x = 1.0;
// end ExtendsMod2;
// endResult
