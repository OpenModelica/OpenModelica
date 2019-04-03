// name: SubscriptTypename2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model SubscriptTypename2
  Real x(stateSelect = StateSelect[1].never);
end SubscriptTypename2;

// Result:
// Error processing file: SubscriptTypename2.mo
// [flattening/modelica/scodeinst/SubscriptTypename2.mo:8:10-8:44:writable] Error: Variable StateSelect[1].never not found in scope SubscriptTypename2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
