// name: TypeRestriction1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

type T
  extends Real;
equation
  x = 1;
end T;

class TypeRestriction1
  T t;
end TypeRestriction1;

// Result:
// Error processing file: TypeRestriction1.mo
// [flattening/modelica/declarations/TypeRestriction1.mo:10:3-10:8:writable] Error: Equations are not allowed in type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
