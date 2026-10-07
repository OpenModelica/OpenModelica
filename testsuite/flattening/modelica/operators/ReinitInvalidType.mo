// name:     ReinitInvalidType
// keywords: reinit
// status:   incorrect
//
// Tests that the compiler checks that the first argument to reinit is a Real.
//

class ReinitInvalidType
  Boolean b(start = false);
equation
  when b then
    reinit(b, true);
  end when;
end ReinitInvalidType;

// Result:
// Error processing file: ReinitInvalidType.mo
// [flattening/modelica/operators/ReinitInvalidType.mo:9:3-9:27:writable] Warning: Components are deprecated in class.
// [flattening/modelica/operators/ReinitInvalidType.mo:11:3-13:11:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/operators/ReinitInvalidType.mo:12:5-12:20:writable] Error: The first argument to reinit must be a subtype of Real, but b has type Boolean.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
