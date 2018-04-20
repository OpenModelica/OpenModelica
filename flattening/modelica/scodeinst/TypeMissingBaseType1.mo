// name: TypeMissingBaseType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

type T
end T;

model TypeMissingBaseType1
  T t;
end TypeMissingBaseType1;

// Result:
// Error processing file: TypeMissingBaseType1.mo
// [flattening/modelica/scodeinst/TypeMissingBaseType1.mo:7:1-8:6:writable] Error: Type ‘T‘ does not extend a basic type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
