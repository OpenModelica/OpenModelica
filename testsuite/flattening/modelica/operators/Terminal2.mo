// name:     Terminal2
// keywords: The terminal operator
// status:   incorrect
//
//  The terminal operator returns bool.
//

class Terminal2

  Real t;
equation
 t=2.0*terminal();
end Terminal2;
// Result:
// Error processing file: Terminal2.mo
// [flattening/modelica/operators/Terminal2.mo:10:3-10:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/operators/Terminal2.mo:12:2-12:18:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/operators/Terminal2.mo:12:2-12:18:writable] Error: Cannot resolve type of expression 2.0 * terminal(). The operands have types Real, Boolean in component <NO_COMPONENT>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
