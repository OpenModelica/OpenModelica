// name: FuncBuiltinNoEvent
// keywords: noEvent
// status: correct
// cflags: -d=newInst
//
// Tests the builtin noEvent operator.
//

model FuncBuiltinNoEvent
  Real x = time;
  Real y = noEvent(x);
end FuncBuiltinNoEvent;

// Result:
// Error processing file: FuncBuiltinNoEvent.mo
// [flattening/modelica/scodeinst/FuncBuiltinNoEvent.mo:11:3-11:22:writable] Error: No matching function found for noEvent(x) in component <REMOVE ME>
// candidates are :
//   noEvent()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
