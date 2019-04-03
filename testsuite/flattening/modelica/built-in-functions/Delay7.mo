// name:     Delay7
// keywords: builtin
// status:   incorrect
//
// Test flattening of the builtin function delay.
// Should issue a warning as b is not a parameter or constant.
// Modelica.Electrical.Analog.Lines.TLine* uses delay(x, var)
//

model Delay
  Real x, y;
  Real a = 1.0, b=2.0;
equation
  x = sin(time);
  y = delay(x, a, b);
end Delay;
// Result:
// Error processing file: Delay7.mo
// [flattening/modelica/built-in-functions/Delay7.mo:15:3-15:21:writable] Error: Function argument delayMax=b in call to OpenModelica.Internal.delay3 has variability continuous which is not a parameter expression.
// [flattening/modelica/built-in-functions/Delay7.mo:15:3-15:21:writable] Error: No matching function found for delay in component <NO COMPONENT>
// candidates are .OpenModelica.Internal.delay2<function>(Real expr, Real parameter delayTime) => Real
//  -.OpenModelica.Internal.delay3<function>(Real expr, Real delayTime, Real parameter delayMax) => Real
// Error: Error occurred while flattening model Delay
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
