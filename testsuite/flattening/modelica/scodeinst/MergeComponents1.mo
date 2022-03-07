// name: MergeComponents1
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
  Real z;
end A;

model MergeComponents1
  A a1(x = 1, y = 2, z = 3);
  A a2(x = 4, y = 5, z = 6);
  A a3(x = 7, y = 8, z = 9);
end MergeComponents1;

// Result:
// class MergeComponents1
//   Real[3] $A1.z = {3.0, 6.0, 9.0};
//   Real[3] $A1.y = {2.0, 5.0, 8.0};
//   Real[3] $A1.x = {1.0, 4.0, 7.0};
// end MergeComponents1;
// endResult
