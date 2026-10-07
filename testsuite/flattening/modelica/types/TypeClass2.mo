// name: TypeClass2
// keywords: type
// status: incorrect
//
// Tests type declaration from a regular class, should be illegal
//

class IllegalClass
  Integer i;
end IllegalClass;

type IllegalType = IllegalClass;

model TypeClass2
  IllegalType it;
equation
  it.i = 1;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TypeClass2;
// Result:
// Error processing file: TypeClass2.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/types/TypeClass2.mo:12:1-12:32:writable] Error: Class specialization violation: .IllegalClass is a new def, not a type.
// Error: Error occurred while flattening model TypeClass2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
