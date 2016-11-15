// name: ClassAsComponentError
// keywords: type error
// status: incorrect
// cflags: -d=newInst
//
// Checks that an error is output if a class is used as a component.
//

model ClassAsComponentError
  model M end M;
equation
  M = 3;
end ClassAsComponentError;

// Result:
// Error processing file: ClassAsComponentError.mo
// [flattening/modelica/scodeinst/ClassAsComponentError.mo:12:3-12:8:writable] Error: Expected M to be a component, but found class instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
