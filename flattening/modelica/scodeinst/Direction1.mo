// name: Direction1
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the direction of components are set correctly in the flat model.
// 

model A
  input Real x;
  C c;
end A;

connector C
  input Real e;
end C;

model Direction1
  output Real x; // Top-scope variable should keep direction.
  A a; // Non top-scope variables should not keep direction.
  C c; // Variable in top-scope connector should keep direction.
end Direction1;

// Result:
// class Direction1
//   output Real x;
//   Real a.x;
//   Real a.c.e;
//   input Real c.e;
// end Direction1;
// endResult
