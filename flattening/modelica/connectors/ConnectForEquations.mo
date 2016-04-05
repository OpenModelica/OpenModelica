// name:     ConnectForEquations
// keywords: <insert keywords here>
// status:   correct
//
// Drmodelica: 8.2  connect equations (p. 244)
//

model Test

model ResistorCircuit
  Modelica.Electrical.Analog.Basic.Resistor R1(R = 100);
  Modelica.Electrical.Analog.Basic.Resistor R2(R = 200);
  Modelica.Electrical.Analog.Basic.Resistor R3(R = 300);
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end ResistorCircuit;

class RegComponent
  parameter Integer n;
  Modelica.Electrical.Analog.Basic.Resistor r_components[n];
  Modelica.Electrical.Analog.Basic.Capacitor C;
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Sources.SineVoltage src(V=10);
equation
  for i in 1:n-1 loop
  connect(r_components[i].n, r_components[i + 1].p);
  end for;
  connect(G.p,C.n);
  connect(C.p,r_components[n].n);
  connect(r_components[1].p,src.p);
  connect(src.n,G.p);
end RegComponent;


  RegComponent rc(n = 6);
end Test;

// Result:
// class Test
// parameter Integer rc.n = 6;
// Real rc.r_components[1].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[1].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[1].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[1].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[1].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[1].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[1].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.r_components[2].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[2].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[2].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[2].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[2].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[2].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[2].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.r_components[3].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[3].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[3].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[3].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[3].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[3].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[3].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.r_components[4].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[4].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[4].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[4].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[4].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[4].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[4].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.r_components[5].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[5].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[5].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[5].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[5].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[5].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[5].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.r_components[6].v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.r_components[6].i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.r_components[6].p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[6].p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.r_components[6].n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.r_components[6].n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.r_components[6].R(quantity = "Resistance", unit = "Ohm", min = 0.0) = 1 "Resistance";
// Real rc.C.v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.C.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.C.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.C.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.C.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.C.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.C.C(quantity = "Capacitance", unit = "F", min = 0.0) = 1 "Capacitance";
// Real rc.G.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.G.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.src.v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
// Real rc.src.i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
// Real rc.src.p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.src.p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// Real rc.src.n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
// Real rc.src.n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
// parameter Real rc.src.offset(quantity = "ElectricPotential", unit = "V") = 0 "Voltage offset";
// parameter Real rc.src.startTime(quantity = "Time", unit = "s") = 0 "Time offset";
// Real rc.src.signalSource.y "Connector of Real output signal";
// parameter Real rc.src.signalSource.amplitude = rc.src.V "Amplitude of sine wave";
// parameter Real rc.src.signalSource.freqHz(quantity = "Frequency", unit = "Hz") = rc.src.freqHz "Frequency of sine wave";
// parameter Real rc.src.signalSource.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = rc.src.phase "Phase of sine wave";
// parameter Real rc.src.signalSource.offset = rc.src.offset "Offset of output signal";
// parameter Real rc.src.signalSource.startTime(quantity = "Time", unit = "s") = rc.src.startTime "Output = offset for time < startTime";
// protected constant Real rc.src.signalSource.pi = 3.14159265358979;
// parameter Real rc.src.V(quantity = "ElectricPotential", unit = "V") = 10 "Amplitude of sine wave";
// parameter Real rc.src.phase(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0 "Phase of sine wave";
// parameter Real rc.src.freqHz(quantity = "Frequency", unit = "Hz") = 1 "Frequency of sine wave";
// equation
//   rc.r_components[1].R * rc.r_components[1].i = rc.r_components[1].v;
//   rc.r_components[1].v = rc.r_components[1].p.v - rc.r_components[1].n.v;
//   0.0 = rc.r_components[1].p.i + rc.r_components[1].n.i;
//   rc.r_components[1].i = rc.r_components[1].p.i;
//   rc.r_components[2].R * rc.r_components[2].i = rc.r_components[2].v;
//   rc.r_components[2].v = rc.r_components[2].p.v - rc.r_components[2].n.v;
//   0.0 = rc.r_components[2].p.i + rc.r_components[2].n.i;
//   rc.r_components[2].i = rc.r_components[2].p.i;
//   rc.r_components[3].R * rc.r_components[3].i = rc.r_components[3].v;
//   rc.r_components[3].v = rc.r_components[3].p.v - rc.r_components[3].n.v;
//   0.0 = rc.r_components[3].p.i + rc.r_components[3].n.i;
//   rc.r_components[3].i = rc.r_components[3].p.i;
//   rc.r_components[4].R * rc.r_components[4].i = rc.r_components[4].v;
//   rc.r_components[4].v = rc.r_components[4].p.v - rc.r_components[4].n.v;
//   0.0 = rc.r_components[4].p.i + rc.r_components[4].n.i;
//   rc.r_components[4].i = rc.r_components[4].p.i;
//   rc.r_components[5].R * rc.r_components[5].i = rc.r_components[5].v;
//   rc.r_components[5].v = rc.r_components[5].p.v - rc.r_components[5].n.v;
//   0.0 = rc.r_components[5].p.i + rc.r_components[5].n.i;
//   rc.r_components[5].i = rc.r_components[5].p.i;
//   rc.r_components[6].R * rc.r_components[6].i = rc.r_components[6].v;
//   rc.r_components[6].v = rc.r_components[6].p.v - rc.r_components[6].n.v;
//   0.0 = rc.r_components[6].p.i + rc.r_components[6].n.i;
//   rc.r_components[6].i = rc.r_components[6].p.i;
//   rc.C.i = rc.C.C * der(rc.C.v);
//   rc.C.v = rc.C.p.v - rc.C.n.v;
//   0.0 = rc.C.p.i + rc.C.n.i;
//   rc.C.i = rc.C.p.i;
//   rc.G.p.v = 0.0;
//   rc.src.signalSource.y = rc.src.signalSource.offset + (if time < rc.src.signalSource.startTime then 0.0 else rc.src.signalSource.amplitude * Modelica.Math.sin(6.28318530717959 * rc.src.signalSource.freqHz * (time - rc.src.signalSource.startTime) + rc.src.signalSource.phase));
//   rc.src.v = rc.src.signalSource.y;
//   rc.src.v = rc.src.p.v - rc.src.n.v;
//   0.0 = rc.src.p.i + rc.src.n.i;
//   rc.src.i = rc.src.p.i;
//   rc.src.n.i + rc.G.p.i + rc.C.n.i = 0.0;
//   rc.src.n.v = rc.G.p.v;
//   rc.G.p.v = rc.C.n.v;
//   rc.r_components[1].p.i + rc.src.p.i = 0.0;
//   rc.r_components[1].p.v = rc.src.p.v;
//   rc.C.p.i + rc.r_components[6].n.i = 0.0;
//   rc.C.p.v = rc.r_components[6].n.v;
//   rc.r_components[5].n.i + rc.r_components[6].p.i = 0.0;
//   rc.r_components[5].n.v = rc.r_components[6].p.v;
//   rc.r_components[4].n.i + rc.r_components[5].p.i = 0.0;
//   rc.r_components[4].n.v = rc.r_components[5].p.v;
//   rc.r_components[3].n.i + rc.r_components[4].p.i = 0.0;
//   rc.r_components[3].n.v = rc.r_components[4].p.v;
//   rc.r_components[2].n.i + rc.r_components[3].p.i = 0.0;
//   rc.r_components[2].n.v = rc.r_components[3].p.v;
//   rc.r_components[1].n.i + rc.r_components[2].p.i = 0.0;
//   rc.r_components[1].n.v = rc.r_components[2].p.v;
// end Test;
// endResult
