// name: MergeComponents5
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
end A;

type A3 = A[3](x = {1, 2, 3});

model MergeComponents5
  A3 a1(y = {1, 2, 3});
  A3 a2(y = {4, 5, 6});
  A3 a3(y = {7, 8, 9});
end MergeComponents5;

// Result:
// class MergeComponents5
//   Real[3, 3] $A31.y = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}};
//   Real[3, 3] $A31.x = {{1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}};
// end MergeComponents5;
// endResult
