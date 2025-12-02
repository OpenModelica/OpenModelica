// name: Clock2
// keywords:
// status: incorrect
//

model Clock
  Real t;
end Clock;

model Clock2
  Clock c;
end Clock2;

// Result:
// Error processing file: Clock2.mo
// [lib/omc/NFModelicaBuiltin.mo:47:1-49:10:writable] Notification: From here:
// [flattening/modelica/scodeinst/Clock2.mo:6:1-8:10:writable] Error: An element with name Clock is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
