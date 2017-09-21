// name: DimRagged1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  parameter Integer n;
  Real a[n];
end A;

model DimRagged1
  A arr[2](n = {2, 3});
end DimRagged1;

// Result:
// Error processing file: DimRagged1.mo
// [flattening/modelica/scodeinst/DimRagged1.mo:9:3-9:12:writable] Error: Ragged dimensions are not yet supported (from dimension '{2, 3}')
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
