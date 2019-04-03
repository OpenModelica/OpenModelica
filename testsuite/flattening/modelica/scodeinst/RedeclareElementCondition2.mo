// name: RedeclareElementCondition2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  replaceable Real x = 1.0 if false;
end A;

model RedeclareElementCondition2
  extends A;

  redeclare Real x if true;
end RedeclareElementCondition2;

// Result:
// Error processing file: RedeclareElementCondition2.mo
// [flattening/modelica/scodeinst/RedeclareElementCondition2.mo:14:3-14:27:writable] Error: Invalid redeclaration of x, a redeclare may not have a condition attribute.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
