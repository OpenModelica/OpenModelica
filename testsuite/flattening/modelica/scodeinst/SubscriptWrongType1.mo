// name: SubscriptWrongType1
// status: incorrect
//

model SubscriptWrongType1
  Real x[3] = {1, 2, 3};
  Real y = x["1"];
end SubscriptWrongType1;

// Result:
// Error processing file: SubscriptWrongType1.mo
// [flattening/modelica/scodeinst/SubscriptWrongType1.mo:7:3-7:18:writable] Error: Subscript '"1"' has type String, expected type Integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
