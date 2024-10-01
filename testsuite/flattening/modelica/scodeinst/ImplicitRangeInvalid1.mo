// name: ImplicitRangeInvalid1
// keywords:
// status: incorrect
//
//

model ImplicitRangeInvalid1
  Real x;
equation
  for i loop
    x = i;
  end for;
end ImplicitRangeInvalid1;

// Result:
// Error processing file: ImplicitRangeInvalid1.mo
// [flattening/modelica/scodeinst/ImplicitRangeInvalid1.mo:10:3-12:10:writable] Error: Identifier i of implicit for iterator must be present as array subscript in the loop body.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
