// name:     Lookup7
// keywords: scoping
// status:   incorrect
//
// Modelica uses lexical scoping.
//

class A
  Real x = y;
end A;

class Lookup7
  Real y;
  A a;
end Lookup7;
// Result:
// Error processing file: Lookup7.mo
// [flattening/modelica/scoping/Lookup7.mo:9:3-9:13:writable] Error: Variable y not found in scope A.
// Error: Error occurred while flattening model Lookup7
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
