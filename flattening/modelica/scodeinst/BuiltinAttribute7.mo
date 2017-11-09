// name: BuiltinAttribute7
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute7
  Real x(redeclare Real start = 1.0);
end BuiltinAttribute7;

// Result:
// Error processing file: BuiltinAttribute7.mo
// [flattening/modelica/scodeinst/BuiltinAttribute7.mo:8:10-8:36:writable] Error: Invalid redeclaration of start, attributes of basic types may not be redeclared.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
