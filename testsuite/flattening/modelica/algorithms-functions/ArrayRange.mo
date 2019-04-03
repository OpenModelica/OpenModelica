// status: incorrect

model ArrayRange
  Real x[4, 2];
algorithm
  for elem in {{1, 2}, {3, 4}, {5, 6}, {7, 8}} loop
    x[div(elem[2], 2), :] := elem;
  end for;
end ArrayRange;

// Result:
// Error processing file: ArrayRange.mo
// [flattening/modelica/algorithms-functions/ArrayRange.mo:6:3-8:10:writable] Error: Iterator elem, has type Integer[4, 2], but expected a 1D array expression.
// Error: Error occurred while flattening model ArrayRange
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
