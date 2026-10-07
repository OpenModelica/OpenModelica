// name:     Partial1
// keywords: partial
// status:   incorrect
//
// This is a test of the `partial' keyword.  The class `A' is declared
// as `partial' which means that it cannot be instantiated.
//

partial class A
  Real x;
end A;

model Partial1
  A a;
end Partial1;
// Result:
// Error processing file: Partial1.mo
// [flattening/modelica/others/Partial1.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/others/Partial1.mo:9:1-11:6:writable] Notification: From here:
// [flattening/modelica/others/Partial1.mo:14:3-14:6:writable] Error: Component 'a' has partial type 'A'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
