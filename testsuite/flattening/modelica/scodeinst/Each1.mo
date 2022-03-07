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
// endResult
