// name:     TempDepResistorCircuitInherited
// keywords: <insert keywords here>
// status:   correct
//
//
// The flattened model should be the same for test TempDepResistorCircuit and
// TempDepResistorCircuitInherited


type ElectricPotential = Real (final quantity="ElectricPotential", final unit ="V");
type Voltage = ElectricPotential;
type ElectricCurrent = Real (final quantity="ElectricCurrent",
     final unit="A");
type Current = ElectricCurrent;

// From Modelica.Electrical.Analog.Interfaces
connector Pin
  Voltage v;
  flow Current i;
end Pin;

model Resistor "Electrical resistor"
  Pin p, n "positive and negative pins";
  Voltage v;
  Current i;
    parameter Real R(unit="Ohm") "Resistance";
  equation
    v = i*R;
end Resistor;

model ResistorCircuit // Circuit of three Resistors connected at one node
  Resistor R1(R = 100);
  Resistor R2(R = 200);
  Resistor R3(R = 300);
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end ResistorCircuit;

model GenericResistorCircuit // The ResistorCircuit made generic
  replaceable Resistor R1(R = 100); // Formal class parameter
  replaceable Resistor R2(R = 200); // Formal class parameter
  replaceable Resistor R3(R = 300); // Formal class parameter
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end GenericResistorCircuit;

model TempResistor
  extends Resistor;
  Real Temp;
  Real RT;
end TempResistor;

model TempDepResistorCircuitInherited
  Real Temp;
  TempResistor R1(R=100, RT=0.1, Temp=Temp);
  TempResistor R2(R=200);
  replaceable Resistor R3(R=300);
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end TempDepResistorCircuitInherited;

// Result:
// class TempDepResistorCircuitInherited
//   Real Temp;
//   Real R1.p.v(quantity = "ElectricPotential", unit = "V");
//   Real R1.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real R1.n.v(quantity = "ElectricPotential", unit = "V");
//   Real R1.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real R1.v(quantity = "ElectricPotential", unit = "V");
//   Real R1.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real R1.R(unit = "Ohm") = 100.0 "Resistance";
//   Real R1.Temp = Temp;
//   Real R1.RT = 0.1;
//   Real R2.p.v(quantity = "ElectricPotential", unit = "V");
//   Real R2.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real R2.n.v(quantity = "ElectricPotential", unit = "V");
//   Real R2.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real R2.v(quantity = "ElectricPotential", unit = "V");
//   Real R2.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real R2.R(unit = "Ohm") = 200.0 "Resistance";
//   Real R2.Temp;
//   Real R2.RT;
//   Real R3.p.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real R3.n.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real R3.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real R3.R(unit = "Ohm") = 300.0 "Resistance";
// equation
//   R1.v = R1.i * R1.R;
//   R2.v = R2.i * R2.R;
//   R3.v = R3.i * R3.R;
//   R2.p.i + R3.p.i + R1.p.i = 0.0;
//   R2.n.i = 0.0;
//   R3.n.i = 0.0;
//   R1.n.i = 0.0;
//   R1.p.v = R2.p.v;
//   R1.p.v = R3.p.v;
// end TempDepResistorCircuitInherited;
// endResult
