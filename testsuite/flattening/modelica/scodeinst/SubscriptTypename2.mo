// name: SubscriptTypename2
// keywords:
// status: incorrect
//

model SubscriptTypename2
  Real x(stateSelect = StateSelect[1].never);
end SubscriptTypename2;

// Result:
// Error processing file: SubscriptTypename2.mo
// [flattening/modelica/scodeinst/SubscriptTypename2.mo:7:10-7:44:writable] Error: Wrong number of subscripts in StateSelect[1].never (0 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
