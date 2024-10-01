// name: RedeclareInvalidVariability1
// keywords:
// status: incorrect
//

model A
  replaceable constant Real x;
end A;

model RedeclareInvalidVariability1
  A a(redeclare parameter Real x);
end RedeclareInvalidVariability1;

// Result:
// Error processing file: RedeclareInvalidVariability1.mo
// [flattening/modelica/scodeinst/RedeclareInvalidVariability1.mo:11:7-11:33:writable] Error: Invalid redeclaration 'parameter x', original element is declared 'constant'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
