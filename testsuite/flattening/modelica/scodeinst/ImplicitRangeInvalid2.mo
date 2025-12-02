// name: ImplicitRangeInvalid2
// keywords:
// status: incorrect
//
//

model ImplicitRangeInvalid2
  Real x[3];
  Real y[4];
equation
  for i loop
    x[i] = y[i];
  end for;
end ImplicitRangeInvalid2;

// Result:
// Error processing file: ImplicitRangeInvalid2.mo
// [flattening/modelica/scodeinst/ImplicitRangeInvalid2.mo:11:3-13:10:writable] Error: Dimension 1 of y and 1 of x differs when trying to deduce implicit iteration range.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
