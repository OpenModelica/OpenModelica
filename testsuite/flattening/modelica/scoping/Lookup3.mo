// name:     Lookup3
// keywords: scoping
// status:   incorrect
//
// Non-constants in an outer scope can not be referred to.
//

class Lookup3
  Real a = 3.0;
  class B
    Real c = a;
  end B;
  B b;
end Lookup3;

// Result:
// Error processing file: Lookup3.mo
// [flattening/modelica/scoping/Lookup3.mo:11:5-11:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup3.mo:9:3-9:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup3.mo:13:3-13:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup3.mo:9:3-9:15:writable] Notification: From here:
// [flattening/modelica/scoping/Lookup3.mo:11:5-11:15:writable] Error: Component 'a' was found in an enclosing scope but is not a constant.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
