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
// endResult
