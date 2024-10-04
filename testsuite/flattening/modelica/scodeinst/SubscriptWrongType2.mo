// name: SubscriptWrongType2
// status: incorrect
//

model SubscriptWrongType2
  type E = enumeration(one, two, three);
  Real x[E];
  Real y = x[1];
end SubscriptWrongType2;

// Result:
// Error processing file: SubscriptWrongType2.mo
// [flattening/modelica/scodeinst/SubscriptWrongType2.mo:8:3-8:16:writable] Error: Subscript '1' has type Integer, expected type enumeration E(one, two, three).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
