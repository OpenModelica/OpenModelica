// name: FuncIntegerWrongType
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that type checking works for Integer.
//

model FuncIntegerWrongType
  Integer i = Integer(1.0);
end FuncIntegerWrongType;

// Result:
// Error processing file: FuncIntegerWrongType.mo
// [flattening/modelica/scodeinst/FuncIntegerWrongType.mo:10:3-10:27:writable] Error: Type mismatch for positional argument 1 in Integer(e=1.0). The argument has type:
//   Real
// expected type:
//   enumeration(:)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
