// name:     Delay5
// keywords: builtin
// status:   incorrect
//
// Test flattening of the builtin function delay.
// Should issue an error as a is not parameter/constant.
//

model Delay
  Real x, y, z;
  Real a=1.0;
equation
  x = sin(time);
  y = delay(x, a);
  z = delay(x, a, a);
end Delay;

// Result:
// Error processing file: Delay5.mo
// [flattening/modelica/built-in-functions/Delay5.mo:14:3-14:18:writable] Error: Function argument delayTime=a in call to OpenModelica.Internal.delay2 has variability continuous which is not a parameter expression.
// [flattening/modelica/built-in-functions/Delay5.mo:14:3-14:18:writable] Error: No matching function found for delay in component <NO COMPONENT>
// candidates are .OpenModelica.Internal.delay2<function>(Real expr, Real parameter delayTime) => Real
//  -.OpenModelica.Internal.delay3<function>(Real expr, Real delayTime, Real parameter delayMax) => Real
// Error: Error occurred while flattening model Delay
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
