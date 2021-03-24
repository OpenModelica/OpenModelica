// name: ImplicitRangeInvalid3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x[:];
  input Real y[size(x, 1)];
  output Real z = 0;
algorithm
  for i loop
    z := z + x[i]*y[i];
  end for;
end f;

model ImplicitRangeInvalid3
  Real x = f({1, 2, 3}, {4, 5, 6});
end ImplicitRangeInvalid3;

// Result:
// Error processing file: ImplicitRangeInvalid3.mo
// [flattening/modelica/scodeinst/ImplicitRangeInvalid3.mo:13:3-15:10:writable] Error: Dimension 1 of y and 1 of x differs when trying to deduce implicit iteration range.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
