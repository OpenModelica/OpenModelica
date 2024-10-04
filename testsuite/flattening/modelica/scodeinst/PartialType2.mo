// name: PartialType2
// keywords:
// status: incorrect
//

partial model A
  Real x;
end A;

model B = A;

model PartialType2
  B b;
end PartialType2;

// Result:
// Error processing file: PartialType2.mo
// [flattening/modelica/scodeinst/PartialType2.mo:10:1-10:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/PartialType2.mo:13:3-13:6:writable] Error: Component 'b' has partial type 'B'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
