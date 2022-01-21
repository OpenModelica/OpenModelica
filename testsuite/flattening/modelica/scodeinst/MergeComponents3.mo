// name: MergeComponents3
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
  Real z;
end A;

model MergeComponents3
  A a1(x = 1, y(start = 5) = 2, z = 3);
  A a2(x = 4, y = 5, z = 6);
  A a3(x = 7, y(start = 3) = 8, z = 9);
end MergeComponents3;

// Result:
// class MergeComponents3
//   Real a2.x = 4.0;
//   Real a2.y = 5.0;
//   Real a2.z = 6.0;
//   Real[2] $A1.z = {3.0, 9.0};
//   Real[2] $A1.y(start = {5.0, 3.0}) = {2.0, 8.0};
//   Real[2] $A1.x = {1.0, 7.0};
// end MergeComponents3;
// endResult
