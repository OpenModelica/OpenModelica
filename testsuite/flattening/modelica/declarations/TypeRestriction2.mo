// name: TypeRestriction2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

type T
  extends Real;
algorithm
  x := 1;
end T;

class TypeRestriction2
  T t;
end TypeRestriction2;

// Result:
// Error processing file: TypeRestriction2.mo
// [flattening/modelica/declarations/TypeRestriction2.mo:10:3-10:9:writable] Error: Algorithm sections are not allowed in type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
