// name: SubscriptedExp2
// status: incorrect
//
//

model SubscriptedExp2
  Real y = (1, 2, 3)[2];
end SubscriptedExp2;

// Result:
// Error processing file: SubscriptedExp2.mo
// Failed to parse file: SubscriptedExp2.mo!
//
// [flattening/modelica/scodeinst/SubscriptedExp2.mo:7:12-7:23:writable] Error: Tuple expression can not be subscripted.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: SubscriptedExp2.mo!
//
// Execution failed!
// endResult
