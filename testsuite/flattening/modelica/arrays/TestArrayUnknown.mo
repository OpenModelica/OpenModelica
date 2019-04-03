// name:     TestArrayUnknown.mo
// keywords: structural parameter giving array dimensions with no binding
// status:   incorrect
//
// Test we fail for a structural parameter with no binding.
//

model TestArrayUnknown
  parameter Integer p;
  model X
    Real x;
  end X;
  X blah[p];
equation
  blah.x = fill(0, p);
end TestArrayUnknown;

// Result:
// Error processing file: TestArrayUnknown.mo
// [flattening/modelica/arrays/TestArrayUnknown.mo:13:3-13:12:writable] Error: Could not evaluate structural parameter (or constant): p which gives dimensions of array: blah[p]. Array dimensions must be known at compile time.
// Error: Error occurred while flattening model TestArrayUnknown
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
