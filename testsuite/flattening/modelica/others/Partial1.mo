// name:     Partial1
// keywords: partial
// status:   incorrect
//
// This is a test of the `partial' keyword.  The class `A' is declared
// as `partial' which means that it cannot be instantiated.
//

partial class A
  Real x;
end A;

model Partial1
  A a;
end Partial1;
// Result:
// Error processing file: Partial1.mo
// [flattening/modelica/others/Partial1.mo:9:1-11:6:writable] Error: Illegal to instantiate partial class A.
// Error: Error occurred while flattening model Partial1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
