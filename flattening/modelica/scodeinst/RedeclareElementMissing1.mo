// name: RedeclareElementMissing1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model RedeclareElementMissing1
  redeclare Real x = 2.0;
end RedeclareElementMissing1;  

// Result:
// Error processing file: RedeclareElementMissing1.mo
// [flattening/modelica/scodeinst/RedeclareElementMissing1.mo:8:3-8:25:writable] Error: Illegal redeclare of element x, no inherited element with that name exists.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
