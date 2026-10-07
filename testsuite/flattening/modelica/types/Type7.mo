// name:     Type7
// keywords: types
// status:   incorrect
//
// This checks that Real and RealType are handled differently
//

class Type7
  Real x;
equation
  x.start = x.start.start;
end Type7;
// Result:
// Error processing file: Type7.mo
// [flattening/modelica/types/Type7.mo:9:3-9:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/Type7.mo:11:3-11:26:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/types/Type7.mo:11:3-11:26:writable] Error: Variable start not found in scope x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
