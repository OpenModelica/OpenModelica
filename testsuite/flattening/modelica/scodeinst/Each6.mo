// name: Each6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model Each6
  A a[3](x(each start = 1.0));
end Each6;

// Result:
// class Each6
//   Real a[1].x(start = 1.0);
//   Real a[2].x(start = 1.0);
//   Real a[3].x(start = 1.0);
// end Each6;
// [flattening/modelica/scodeinst/Each6.mo:12:17-12:28:writable] Warning: 'each' used when modifying non-array element x.
//
// endResult
