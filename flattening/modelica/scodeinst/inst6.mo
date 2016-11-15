// name: inst6.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model M
  package P end P;
  P p;
end M;

// Result:
// Error processing file: inst6.mo
// [flattening/modelica/scodeinst/inst6.mo:9:3-9:6:writable] Error: Invalid specialized class type 'package' for component p.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
