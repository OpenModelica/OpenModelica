// name: Direction2
// keywords:
// status: correct
// cflags: -d=newInst --useLocalDirection
//
// Checks that input/output isn't stripped when useLocalDirection is true. 
// 

model A
  input Real x;
  C c;
end A;

connector C
  input Real e;
end C;

model Direction2
  output Real x; // Top-scope variable should keep direction.
  A a; // Non top-scope variables should not keep direction.
  C c; // Variable in top-scope connector should keep direction.
end Direction2;

// Result:
// class Direction2
//   output Real x;
//   input Real a.x;
//   input Real a.c.e;
//   input Real c.e;
// end Direction2;
// endResult
