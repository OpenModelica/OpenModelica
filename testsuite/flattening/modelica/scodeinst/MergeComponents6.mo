// name: MergeComponents6
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
end A;

model MergeComponents6
  A a1(x = 1, y = 2);
  parameter A a2(x = 3, y = 4);
  A a3(x = 5, y = 6);
  parameter A a4(x = 7, y = 8);
end MergeComponents6;

// Result:
// class MergeComponents6
//   parameter Real[2] $A1.y = {4.0, 8.0};
//   parameter Real[2] $A1.x = {3.0, 7.0};
//   Real[2] $A2.y = {2.0, 6.0};
//   Real[2] $A2.x = {1.0, 5.0};
// end MergeComponents6;
// endResult
