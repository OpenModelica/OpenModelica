// name:     Abs2
// keywords: abs operator
// status:   incorrect
//
//  The abs operator
//


model Abs
  Boolean b;
equation
  b=abs(b);
end Abs;

// Result:
// Error processing file: Abs2.mo
// [flattening/modelica/built-in-functions/Abs2.mo:12:3-12:11:writable] Error: No matching function found for abs in component <NO COMPONENT>
// candidates are .OpenModelica.Internal.intAbs<function>(Integer v) => Integer
//  -.OpenModelica.Internal.realAbs<function>(Real v) => Real
// Error: Error occurred while flattening model Abs
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
