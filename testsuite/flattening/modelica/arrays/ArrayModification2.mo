// name:     ArrayModification2
// keywords: array, modification
// status:   incorrect
//
// Subscripted modifiers are not allowed.
//

class ArrayModification2
  class A
    Real x[3];
  end A;

  extends A(x[2] = 1.0);
end ArrayModification2;

// Result:
// Error processing file: ArrayModification2.mo
// Failed to parse file: ArrayModification2.mo!
//
// [flattening/modelica/arrays/ArrayModification2.mo:13:13-13:14:writable] Error: Subscripting modifiers is not allowed. Apply the modification on the whole identifier using an array-expression or an each-modifier.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ArrayModification2.mo!
//
// Execution failed!
// endResult
