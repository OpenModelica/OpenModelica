// name:     VariableRange
// keywords: equation, range, variable
// status:   incorrect
//
// Checks that variable ranges are not allowed in for-equations.
//

model M
  Real x, y;
equation
  for i in 1:x loop
    y = i;
  end for;
end M;

// Result:
// Error processing file: VariableRange.mo
// [flattening/modelica/equations/VariableRange.mo:11:3-13:10:writable] Error: The iteration range 1.0:x is not a constant or parameter expression.
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
