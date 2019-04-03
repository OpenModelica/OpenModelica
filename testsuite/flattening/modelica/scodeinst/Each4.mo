// name: Each4
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real n;
end A;

model Each4
  A a(n(each fixed=true));
end Each4;

// Result:
// class Each4
//   Real a.n(fixed = true);
// end Each4;
// [flattening/modelica/scodeinst/Each4.mo:12:14-12:24:writable] Warning: 'each' used when modifying non-array element n.
//
// endResult
