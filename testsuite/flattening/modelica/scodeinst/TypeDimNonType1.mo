// name: TypeDimNonType1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real a;
end A;

model TypeDimNonType1
  model B = A[3];
  B b;
end TypeDimNonType1;

// Result:
// class TypeDimNonType1
//   Real b[1].a;
//   Real b[2].a;
//   Real b[3].a;
// end TypeDimNonType1;
// endResult
