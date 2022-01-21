// name: MergeComponents4
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
  Real z;
end A;

model MergeComponents4
  A a1(x = 1, y = 2, z = 3);
  A a2(x = 4, y = 5, z = 6);
  A a3(x = 7, y = 8, z = 9);
equation
  a1.x = a2.y + a3.z;
algorithm
  a2.z := a3.x + a1.y;
end MergeComponents4;

// Result:
// class MergeComponents4
//   Real[3] $A1.z = {3.0, 6.0, 9.0};
//   Real[3] $A1.y = {2.0, 5.0, 8.0};
//   Real[3] $A1.x = {1.0, 4.0, 7.0};
// equation
//   $A1[1].x = $A1[2].y + $A1[3].z;
// algorithm
//   $A1[2].z := $A1[3].x + $A1[1].y;
// end MergeComponents4;
// endResult
