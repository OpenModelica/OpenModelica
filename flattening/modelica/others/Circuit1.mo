// name:     Circuit1
// keywords:
// status:   correct
//
// This is the example from the report.  It is here to have a somewhat
// larger test.
//

type Voltage = Real(unit="V");
type Current = Real(unit="A");


connector Pin
  Voltage      v;
  flow Current i;
end Pin;

partial model TwoPin "Superclass of elements with two electrical pins"
  Pin p, n;
  Voltage v;
  Current i;
equation
  v = p.v - n.v;
  0 = p.i + n.i;
  i = p.i;
end TwoPin;

model Resistor "Ideal electrical resistor"
  extends TwoPin;
  parameter Real R(unit="Ohm") "Resistance";
equation
  R*i = v;
end Resistor;

model Capacitor "Ideal electrical capacitor"
  extends TwoPin;
  parameter Real C(unit="F") "Capacitance";
equation
  C*der(v) = i;
end Capacitor;

model Inductor "Ideal electrical inductor"
  extends TwoPin;
  parameter Real L(unit="H") "Inductance";
equation
  L*der(i) = v;
end Inductor;

model VsourceAC "Sin-wave voltage source"
  extends TwoPin;
  parameter Voltage VA = 220 "Amplitude";
  parameter Real f(unit="Hz") = 50  "Frequency";
  constant  Real PI=3.141592653589793;
equation
  v = VA*sin(2*PI*f*time);
end VsourceAC;

model Ground "Ground"
  Pin p;
equation
  p.v = 0;
end Ground;

model Circuit1
  Resistor  R1(R=10);
  Capacitor C(C=0.01);
  Resistor  R2(R=100);
  Inductor  L(L=0.1);
  VsourceAC AC;
  Ground    G;

equation
  connect (AC.p, R1.p);    // Capacitor circuit
  connect (R1.n, C.p);
  connect (C.n, AC.n);
  connect (R1.p, R2.p);    // Inductor circuit
  connect (R2.n, L.p);
  connect (L.n,  C.n);
  connect (AC.n, G.p);    // Ground
end Circuit1;

// Result:
// class Circuit1
//   Real R1.p.v(unit = "V");
//   Real R1.p.i(unit = "A");
//   Real R1.n.v(unit = "V");
//   Real R1.n.i(unit = "A");
//   Real R1.v(unit = "V");
//   Real R1.i(unit = "A");
//   parameter Real R1.R(unit = "Ohm") = 10.0 "Resistance";
//   Real C.p.v(unit = "V");
//   Real C.p.i(unit = "A");
//   Real C.n.v(unit = "V");
//   Real C.n.i(unit = "A");
//   Real C.v(unit = "V");
//   Real C.i(unit = "A");
//   parameter Real C.C(unit = "F") = 0.01 "Capacitance";
//   Real R2.p.v(unit = "V");
//   Real R2.p.i(unit = "A");
//   Real R2.n.v(unit = "V");
//   Real R2.n.i(unit = "A");
//   Real R2.v(unit = "V");
//   Real R2.i(unit = "A");
//   parameter Real R2.R(unit = "Ohm") = 100.0 "Resistance";
//   Real L.p.v(unit = "V");
//   Real L.p.i(unit = "A");
//   Real L.n.v(unit = "V");
//   Real L.n.i(unit = "A");
//   Real L.v(unit = "V");
//   Real L.i(unit = "A");
//   parameter Real L.L(unit = "H") = 0.1 "Inductance";
//   Real AC.p.v(unit = "V");
//   Real AC.p.i(unit = "A");
//   Real AC.n.v(unit = "V");
//   Real AC.n.i(unit = "A");
//   Real AC.v(unit = "V");
//   Real AC.i(unit = "A");
//   parameter Real AC.VA(unit = "V") = 220.0 "Amplitude";
//   parameter Real AC.f(unit = "Hz") = 50.0 "Frequency";
//   constant Real AC.PI = 3.141592653589793;
//   Real G.p.v(unit = "V");
//   Real G.p.i(unit = "A");
// equation
//   R1.R * R1.i = R1.v;
//   R1.v = R1.p.v - R1.n.v;
//   0.0 = R1.p.i + R1.n.i;
//   R1.i = R1.p.i;
//   C.C * der(C.v) = C.i;
//   C.v = C.p.v - C.n.v;
//   0.0 = C.p.i + C.n.i;
//   C.i = C.p.i;
//   R2.R * R2.i = R2.v;
//   R2.v = R2.p.v - R2.n.v;
//   0.0 = R2.p.i + R2.n.i;
//   R2.i = R2.p.i;
//   L.L * der(L.i) = L.v;
//   L.v = L.p.v - L.n.v;
//   0.0 = L.p.i + L.n.i;
//   L.i = L.p.i;
//   AC.v = AC.VA * sin(6.283185307179586 * AC.f * time);
//   AC.v = AC.p.v - AC.n.v;
//   0.0 = AC.p.i + AC.n.i;
//   AC.i = AC.p.i;
//   G.p.v = 0.0;
//   R1.p.i + R2.p.i + AC.p.i = 0.0;
//   R1.n.i + C.p.i = 0.0;
//   C.n.i + L.n.i + AC.n.i + G.p.i = 0.0;
//   R2.n.i + L.p.i = 0.0;
//   AC.p.v = R1.p.v;
//   AC.p.v = R2.p.v;
//   C.p.v = R1.n.v;
//   AC.n.v = C.n.v;
//   AC.n.v = G.p.v;
//   AC.n.v = L.n.v;
//   L.p.v = R2.n.v;
// end Circuit1;
// endResult
