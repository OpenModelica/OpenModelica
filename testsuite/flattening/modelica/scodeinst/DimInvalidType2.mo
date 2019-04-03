// name: DimInvalidType2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimInvalidType2
  Real x[{1, 2, 3}];
end DimInvalidType2;

// Result:
// Error processing file: DimInvalidType2.mo
// [flattening/modelica/scodeinst/DimInvalidType2.mo:8:3-8:20:writable] Error: Dimension '{1, 2, 3}' of type Integer[3] is not an integer expression or an enumeration or Boolean type name.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
