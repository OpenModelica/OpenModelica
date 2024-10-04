// name: DimInvalidType1
// keywords:
// status: incorrect
//

model DimInvalidType1
  Real x[4.0];
end DimInvalidType1;

// Result:
// Error processing file: DimInvalidType1.mo
// [flattening/modelica/scodeinst/DimInvalidType1.mo:7:3-7:14:writable] Error: Dimension '4.0' of type Real is not an integer expression or an enumeration or Boolean type name.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
