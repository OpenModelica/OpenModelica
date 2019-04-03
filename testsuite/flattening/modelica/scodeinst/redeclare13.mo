// name: redeclare13.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// Checks that redeclares are propagated to the correct element when there's
// multiple extends.
//

model A
  replaceable Real x;
end A;

model B
  replaceable Real y;
end B;

model C
  extends A;
  extends B;
end C;

model D
  C c(redeclare Real x = 3.0);
end D;

// Result:
// class D
//   Real c.x = 3.0;
//   Real c.y;
// end D;
// endResult
