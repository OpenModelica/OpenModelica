// name: PartialClass1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

partial class PartialClass1
end PartialClass1;

// Result:
// Error processing file: PartialClass1.mo
// [flattening/modelica/scodeinst/PartialClass1.mo:7:1-8:18:writable] Error: Illegal to instantiate partial class PartialClass1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
