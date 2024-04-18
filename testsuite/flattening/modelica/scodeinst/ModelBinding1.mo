// name: ModelBinding1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real x;
end A;

model ModelBinding1
  A a1;
  A a2 = a1;
end ModelBinding1;

// Result:
// Error processing file: ModelBinding1.mo
// [flattening/modelica/scodeinst/ModelBinding1.mo:13:3-13:12:writable] Error: Component 'a2' may not have a binding equation due to class specialization 'model'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
