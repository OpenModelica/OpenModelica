// name: Connect12
// keywords: array, connector, extending basictype
// status: correct
// cflags: +std=2.x
//
// This test is for connectors extending a basictype.
// New in Modelica v2.2.
//


connector RealSignal
  replaceable type SignalType = Real;
 extends SignalType;
end RealSignal;

connector RealInput = input RealSignal;
connector RealOutput = output RealSignal;
connector RealInput2 = input RealSignal(redeclare type SignalType = Real[2]);
connector RealOutput2 = output RealSignal(redeclare type SignalType = Real[2]);

model test
  RealInput x;
  RealOutput x2;
  RealInput2 v={1.,2.4};
  RealOutput2 v2;
  Real y;
  Real w[2];

equation
      x-y=0;
   connect(x,x2);
   connect(v,v2);
end test;

// Result:
// class test
//   input Real x;
//   output Real x2;
//   input Real v = {1.0, 2.4};
//   output Real v2;
//   Real y;
//   Real w[1];
//   Real w[2];
// equation
//   v = {1.0, 2.4};
//   x - y = 0.0;
//   x = x2;
//   v[1] = v2[1];
//   v[2] = v2[2];
// end test;
// endResult
