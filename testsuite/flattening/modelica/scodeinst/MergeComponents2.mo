// name: MergeComponents2
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  Real x;
  Real y;
  Real z;
end A;

model MergeComponents2
  A a1(x = 1, y = 2, z = 3);
  A a2(z = 4, y = 5, x = 6);
  A a3(y = 7, x = 8, z = 9);
end MergeComponents2;

// Result:
// class MergeComponents2
//   Real[3] $A1.z = {3.0, 4.0, 9.0};
//   Real[3] $A1.y = {2.0, 5.0, 7.0};
//   Real[3] $A1.x = {1.0, 6.0, 8.0};
// end MergeComponents2;
// endResult
