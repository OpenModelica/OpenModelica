// name: DimNegative1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimNegative1
  Real x[-1];
end DimNegative1;


// Result:
// Error processing file: DimNegative1.mo
// [flattening/modelica/scodeinst/DimNegative1.mo:8:3-8:13:writable] Error: Negative dimension index (-1) for component x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
