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
//   parameter Integer n = 3;
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   input Real u[1];
//   input Real u[2];
//   input Real u[3];
//   parameter Real delayMax(min = 0.0, start = 1.0) "maximum delay time";
//   input Real delayTime;
// equation
//   y[1] = delay(u[1], delayTime, delayMax);
//   y[2] = delay(u[2], delayTime, delayMax);
//   y[3] = delay(u[3], delayTime, delayMax);
// end Delay8;
// endResult
