// name: ErrorMultipleClasses
// status: incorrect

class A
end A;

class A
end A;

class sin
end sin;
// Result:
// Error processing file: ErrorMultipleClasses.mo
// [flattening/modelica/declarations/ErrorMultipleClasses.mo:7:1-8:6:writable] Error: An element with name A is already declared in this scope.
// Error: Error occurred while flattening model sin
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
