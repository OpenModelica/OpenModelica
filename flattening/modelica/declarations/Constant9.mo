// name:     Constant9
// keywords: constant, package
// status:   incorrect
//
// Lookup of variables in packages must result in variable being constant. Parameters and variables
// are not allowed to look up in packages.


package A
  parameter Real x=1;
end A;

model test
  Real x=A.x;
end test;
// Result:
// Error processing file: Constant9.mo
// Error: Variable A.x in package A is not constant.
// [flattening/modelica/declarations/Constant9.mo:14:3-14:13:writable] Error: Variable A.x not found in scope test.
// Error: Error occurred while flattening model test
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
