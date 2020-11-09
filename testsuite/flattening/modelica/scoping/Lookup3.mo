// name:     Lookup3
// keywords: scoping
// status:   incorrect
// cflags: -d=-newInst
//
// Non-constants in an outer scope can not be referred to.
//

class Lookup3
  Real a = 3.0;
  class B
    Real c = a;
  end B;
  B b;
end Lookup3;

// Result:
// Error processing file: Lookup3.mo
// [flattening/modelica/scoping/Lookup3.mo:14:3-14:6:writable] Error: Variable b: Variable a in package Lookup3 is not constant.
// [flattening/modelica/scoping/Lookup3.mo:12:5-12:15:writable] Error: Variable a not found in scope Lookup3.B.
// Error: Error occurred while flattening model Lookup3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
