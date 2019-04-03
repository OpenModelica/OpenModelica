// name:     InvalidSizeIndex2
// keywords: size scalar
// status:   incorrect
//
// Checks that it's not allowed to use and out of bounds index with size.
//

model InvalidSizeIndex2
  Real r[4, 2];
  Real s = size(r, 3);
end InvalidSizeIndex2;

// Result:
// Error processing file: InvalidSizeIndex2.mo
// [flattening/modelica/built-in-functions/InvalidSizeIndex2.mo:10:3-10:22:writable] Error: Invalid index 3 in call to size of r, valid index interval is [1,2].
// Error: Error occurred while flattening model InvalidSizeIndex2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
