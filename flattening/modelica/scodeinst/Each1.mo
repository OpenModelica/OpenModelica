// name: Each1
// keywords:
// status: correct
// cflags: -d=newInst
//

model N
  Real r;
end N;

model Each1
  N n(each r = 1.0);
end Each1;

// Result:
// class Each1
//   Real n.r = 1.0;
// end Each1;
// [flattening/modelica/scodeinst/Each1.mo:12:12-12:19:writable] Warning: 'each' used when modifying non-array element n.
//
// endResult
