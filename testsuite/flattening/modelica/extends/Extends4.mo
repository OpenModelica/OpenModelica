// name:     Extends4
// keywords: extends basictype cat operator
// status:   correct
// cflags:   +std=2.x
//
// Testing extending basic type and contatenation operators (MC bug #643)

connector RealSignal
 replaceable type SignalType = Real;
 extends SignalType;
end RealSignal;

connector RealInput= input RealSignal;
connector RealOutput = output RealSignal;

block Multiplex3 "Multiplexer block for three input connectors"
  parameter Integer n1=1 "dimension of input signal connector 1";
  parameter Integer n2=1 "dimension of input signal connector 2";
  parameter Integer n3=1 "dimension of input signal connector 3";
 RealInput u1[n1];
 RealInput u2[n2];
 RealInput u3[n3];

 RealOutput y[n1+n2+n3];

equation
  [y]=[u1;u2;u3];
end Multiplex3;

// Result:
// class Multiplex3 "Multiplexer block for three input connectors"
//   parameter Integer n1 = 1 "dimension of input signal connector 1";
//   parameter Integer n2 = 1 "dimension of input signal connector 2";
//   parameter Integer n3 = 1 "dimension of input signal connector 3";
//   input Real u1[1];
//   input Real u2[1];
//   input Real u3[1];
//   output Real y[1];
//   output Real y[2];
//   output Real y[3];
// equation
//   y[1] = u1[1];
//   y[2] = u2[1];
//   y[3] = u3[1];
// end Multiplex3;
// endResult
