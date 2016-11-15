// name: MultiInheritanceRedeclare2
// keywords:
// status: correct
// cflags: -d=newInst
//

model M
  Real x;
end M;

model A
  replaceable model M end M;
  M m1;
end A;

model B
  replaceable model M end M;
  M m2;
end B;

model C
  extends A;
  extends B;
end C;

model MultiInheritanceRedeclare2
  C c(redeclare model M = M);
end MultiInheritanceRedeclare2;

// Result:
// class MultiInheritanceRedeclare2
//   Real c.m1.x;
//   Real c.m2.x;
// end MultiInheritanceRedeclare2;
// endResult
