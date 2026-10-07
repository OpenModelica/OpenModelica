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
// [flattening/modelica/algorithms-functions/ArrayRange.mo:7:5-7:34:writable] Error: Wrong number of subscripts in elem[2] (1 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
