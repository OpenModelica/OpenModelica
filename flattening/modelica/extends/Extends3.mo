// name:     Extends3
// keywords: extends basictype operators
// status:   correct
// cflags:   +std=2.x
//
// Testing extending basic type and matrix multiplication operators (MC bug #643)

connector RealSignal
  replaceable type SignalType = Real;
  extends SignalType;
end RealSignal;

connector RealInput = input RealSignal;
connector RealOutput = output RealSignal;

block SS
  RealInput u[nin];
  RealOutput y[nout];
  parameter Integer nin=1;
  parameter Integer nout=2;
  parameter Real B[2,1] = {{1},{2}};
equation
  y = B*u;
end SS;



// Result:
// class SS
//   input Real u[1];
//   output Real y[1];
//   output Real y[2];
//   parameter Integer nin = 1;
//   parameter Integer nout = 2;
//   parameter Real B[1,1] = 1.0;
//   parameter Real B[2,1] = 2.0;
// equation
//   y[1] = B[1,1] * u[1];
//   y[2] = B[2,1] * u[1];
// end SS;
// endResult
