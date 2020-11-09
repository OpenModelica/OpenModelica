// name:     RecursiveDefinition
// keywords: recursive definition
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that compiler gives an error for recursive definitions.
//

class A

  class B
    A x;
  end B;

  B b;
end A;

// Result:
// Error processing file: RecursiveDefinition.mo
// [flattening/modelica/others/RecursiveDefinition.mo:12:5-12:8:writable] Error: Declaration of element x causes recursive definition of class A.
// Error: Error occurred while flattening model A
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
