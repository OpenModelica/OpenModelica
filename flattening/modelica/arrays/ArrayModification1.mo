// name:     ArrayModification1
// keywords: array, modification
// status:   incorrect
//
// Subscripted modifiers are not allowed.
//

class ArrayModification1
  class A
    Real x[3];
  end A;
  A a(x[2] = 1.0);
end ArrayModification1;

// Result:
// Error processing file: ArrayModification1.mo
// Failed to parse file: ArrayModification1.mo!
//
// [flattening/modelica/arrays/ArrayModification1.mo:12:7-12:8:writable] Error: Subscripting modifiers is not allowed. Apply the modification on the whole identifier using an array-expression or an each-modifier.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ArrayModification1.mo!
//
// Execution failed!
// endResult
