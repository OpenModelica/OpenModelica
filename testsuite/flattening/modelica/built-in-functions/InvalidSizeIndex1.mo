// name:     InvalidSizeIndex1
// keywords: size scalar
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that it's not allowed to use and out of bounds index with size.
//

model InvalidSizeIndex1
  Real r[4, 2];
  Real s = size(r, 0);
end InvalidSizeIndex1;

// Result:
// Error processing file: InvalidSizeIndex1.mo
// [flattening/modelica/built-in-functions/InvalidSizeIndex1.mo:11:3-11:22:writable] Error: Invalid index 0 in call to size of r, valid index interval is [1,2].
// Error: Error occurred while flattening model InvalidSizeIndex1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
