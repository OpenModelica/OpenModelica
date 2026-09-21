// name: inst6.mo
// keywords:
// status: incorrect
// suite: disabled
//

model M
  package P end P;
  P p;
end M;

// Result:
// Error processing file: inst6.mo
// [flattening/modelica/scodeinst/inst6.mo:10:3-10:6:writable] Error: Invalid specialized class type 'package' for component p.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
