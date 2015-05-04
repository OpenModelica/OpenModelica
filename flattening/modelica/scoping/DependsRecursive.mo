// name:     DependsRecursive
// keywords: scoping
// status:   incorrect
//
// A recursive model can not be instantiated.
//

model DependsRecursive
  Real head;
  DependsRecursive tail;
end DependsRecursive;
// Result:
// Error processing file: DependsRecursive.mo
// [flattening/modelica/scoping/DependsRecursive.mo:10:3-10:24:writable] Error: Declaration of element tail causes recursive definition of class DependsRecursive.
// Error: Error occurred while flattening model DependsRecursive
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
