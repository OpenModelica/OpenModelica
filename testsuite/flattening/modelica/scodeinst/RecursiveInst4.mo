// name: RecursiveInst4
// keywords:
// status: correct
//
// A class can occur again in the instance tree if the tree is finite.
//

model Empty
  Real x;
end Empty;

model A
  replaceable model R = Empty;
  R r;
end A;

model C
  A a;
end C;

model RecursiveInst4
  A a(redeclare model R = C);
end RecursiveInst4;

// Result:
// class RecursiveInst4
//   Real a.r.a.r.x;
// end RecursiveInst4;
// endResult
