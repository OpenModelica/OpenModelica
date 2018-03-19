// name:     MissingRedeclare1
// keywords: redeclare, modification, replaceable
// status:   incorrect
// cflags:   -d=newInst
//
// Checks that it's not allowed to redeclare a class without using redeclare.
//

model A
  model B
    Real x;
  end B;

  B b;
end A;

model MissingRedeclare1
  model C
    Real x;
    Real y;
  end C;

  A a(B = C);
end MissingRedeclare1;

// Result:
// Error processing file: MissingRedeclare1.mo
// [flattening/modelica/scodeinst/MissingRedeclare1.mo:23:7-23:12:writable] Error: Missing redeclare keyword on attempted redeclaration of class B.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
