// name: Delay8
// status: correct

block Delay8 "Delay block with variable DelayTime"
  parameter Integer n=3;
  Real y[n];
  input Real u[n];
  parameter Real delayMax(min=0, start=1) "maximum delay time";
  input Real delayTime;
equation
  y[:] = delay(u[:], delayTime, delayMax);
end Delay8;

// Result:
// class Delay8 "Delay block with variable DelayTime"
//   final parameter Integer n = 3;
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   input Real u[1];
//   input Real u[2];
//   input Real u[3];
//   parameter Real delayMax(min = 0.0, start = 1.0) = 1.0 "maximum delay time";
//   input Real delayTime;
// equation
//   y[:] = array(delay(u[$i0], delayTime, delayMax) for $i0 in 1:3);
// end Delay8;
// [flattening/modelica/built-in-functions/Delay8.mo:8:3-8:63:writable] Warning: Parameter delayMax has no value, and is fixed during initialization (fixed=true), using available start value (start=1) as default value.
//
// endResult
