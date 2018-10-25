// name: ConditionInvalidBinding1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConditionInvalidBinding1
  Real x = "string" if true;
end ConditionInvalidBinding1;

// Result:
// Error processing file: ConditionInvalidBinding1.mo
// [flattening/modelica/scodeinst/ConditionInvalidBinding1.mo:8:3-8:28:writable] Error: Type mismatch in binding x = "string", expected subtype of Real, got type String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
