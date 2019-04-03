// name:     RefinedSimpleCircuitValid
// keywords: <insert keywords here>
// status:   correct
//
//
// Sometimes it can be useful to allow a more general constraining type of
// a class parameter, e.g. TwoPin instead of Resistor for the formal class
// parameters and components comp1 and comp2 below. This allows replacement
// by another kind of electrical component than a resistor in the circuit.
//

  type ElectricPotential = Real (final quantity="ElectricPotential", final unit
        ="V");
  type Voltage = ElectricPotential;
  type ElectricCurrent = Real (final quantity="ElectricCurrent", final unit="A");
  type Current = ElectricCurrent;
  type Capacitance = Real (
      final quantity="Capacitance",
      final unit="F",
      min=0);
  type Inductance = Real (
      final quantity="Inductance",
      final unit="H",
      min=0);


  // From Modelica.Electrical.Analog.Interfaces
  connector Pin
    Voltage v;
    flow Current i;
  end Pin;

  model Resistor "Electrical resistor"
    Pin p;
    Pin n "positive and negative pins";
    Voltage v;
    Current i;
    parameter Real R(unit="Ohm") "Resistance";
  equation
    v = i*R;
  end Resistor;

  partial class TwoPin
    "Superclass of elements with two electrical pins"
    Pin p;
    Pin n;
    Voltage v;
    Current i;
  equation
    v = p.v - n.v;
    p.i + n.i = 0;
    i = p.i;
  end TwoPin;

  model Capacitor "Ideal linear electrical capacitor"
    extends TwoPin;
    parameter Capacitance C=1 "Capacitance";
  equation
    i = C*der(v);
  end Capacitor;

  model Inductor "Ideal linear electrical inductor"
    extends TwoPin;
    parameter Inductance L=1 "Inductance";
  equation
    L*der(i) = v;
  end Inductor;

  model TempResistor
    extends Resistor;
    Real Temp;
    Real RT;
  end TempResistor;

  model GeneralSimpleCircuit
    replaceable Resistor comp1(R=100) extends TwoPin;
    replaceable Resistor comp2(R=200) extends TwoPin;
    TempResistor R3(R=300);
  equation
    connect(comp1.p, comp2.p);
    connect(comp1.p, R3.p);
  end GeneralSimpleCircuit;

  model RefinedSimpleCircuit
    extends GeneralSimpleCircuit(redeclare Capacitor comp1(C=0.003), redeclare
        Inductor comp2(L=0.0002));
  end RefinedSimpleCircuit;

// class RefinedSimpleCircuit
// Real comp1.p.v(quantity = "ElectricPotential", unit = "V");
// Real comp1.p.i(quantity = "ElectricCurrent", unit = "A");
// Real comp1.n.v(quantity = "ElectricPotential", unit = "V");
// Real comp1.n.i(quantity = "ElectricCurrent", unit = "A");
// Real comp1.v(quantity = "ElectricPotential", unit = "V");
// Real comp1.i(quantity = "ElectricCurrent", unit = "A");
// parameter Real comp1.C(quantity = "Capacitance", unit = "F", min = 0.0) = 0.003 "Capacitance";
// Real comp2.p.v(quantity = "ElectricPotential", unit = "V");
// Real comp2.p.i(quantity = "ElectricCurrent", unit = "A");
// Real comp2.n.v(quantity = "ElectricPotential", unit = "V");
// Real comp2.n.i(quantity = "ElectricCurrent", unit = "A");
// Real comp2.v(quantity = "ElectricPotential", unit = "V");
// Real comp2.i(quantity = "ElectricCurrent", unit = "A");
// parameter Real comp2.L(quantity = "Inductance", unit = "H", min = 0.0) = 0.0002 "Inductance";
// Real R3.p.v(quantity = "ElectricPotential", unit = "V");
// Real R3.p.i(quantity = "ElectricCurrent", unit = "A");
// Real R3.n.v(quantity = "ElectricPotential", unit = "V");
// Real R3.n.i(quantity = "ElectricCurrent", unit = "A");
// Real R3.v(quantity = "ElectricPotential", unit = "V");
// Real R3.i(quantity = "ElectricCurrent", unit = "A");
// parameter Real R3.R(unit = "Ohm") = 300.0 "Resistance";
// Real R3.Temp;
// Real R3.RT;
// equation
//   comp1.i = comp1.C * der(comp1.v);
//   comp1.v = comp1.p.v - comp1.n.v;
//   comp1.p.i + comp1.n.i = 0.0;
//   comp1.i = comp1.p.i;
//   comp2.L * der(comp2.i) = comp2.v;
//   comp2.v = comp2.p.v - comp2.n.v;
//   comp2.p.i + comp2.n.i = 0.0;
//   comp2.i = comp2.p.i;
//   R3.v = R3.i * R3.R;
//   comp1.p.i + (comp2.p.i + R3.p.i) = 0.0;
//   comp1.p.v = comp2.p.v;
//   comp2.p.v = R3.p.v;
//   comp1.n.i = 0.0;
//   R3.n.i = 0.0;
//   comp2.n.i = 0.0;
// end RefinedSimpleCircuit;
// Result:
// class RefinedSimpleCircuit
//   Real comp1.p.v(quantity = "ElectricPotential", unit = "V");
//   Real comp1.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real comp1.n.v(quantity = "ElectricPotential", unit = "V");
//   Real comp1.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real comp1.v(quantity = "ElectricPotential", unit = "V");
//   Real comp1.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real comp1.C(quantity = "Capacitance", unit = "F", min = 0.0) = 0.003 "Capacitance";
//   Real comp2.p.v(quantity = "ElectricPotential", unit = "V");
//   Real comp2.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real comp2.n.v(quantity = "ElectricPotential", unit = "V");
//   Real comp2.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real comp2.v(quantity = "ElectricPotential", unit = "V");
//   Real comp2.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real comp2.L(quantity = "Inductance", unit = "H", min = 0.0) = 0.0002 "Inductance";
//   Real R3.p.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.p.i(quantity = "ElectricCurrent", unit = "A");
//   Real R3.n.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.n.i(quantity = "ElectricCurrent", unit = "A");
//   Real R3.v(quantity = "ElectricPotential", unit = "V");
//   Real R3.i(quantity = "ElectricCurrent", unit = "A");
//   parameter Real R3.R(unit = "Ohm") = 300.0 "Resistance";
//   Real R3.Temp;
//   Real R3.RT;
// equation
//   comp1.i = comp1.C * der(comp1.v);
//   comp1.v = comp1.p.v - comp1.n.v;
//   comp1.p.i + comp1.n.i = 0.0;
//   comp1.i = comp1.p.i;
//   comp2.L * der(comp2.i) = comp2.v;
//   comp2.v = comp2.p.v - comp2.n.v;
//   comp2.p.i + comp2.n.i = 0.0;
//   comp2.i = comp2.p.i;
//   R3.v = R3.i * R3.R;
//   comp1.p.i + comp2.p.i + R3.p.i = 0.0;
//   comp1.n.i = 0.0;
//   comp2.n.i = 0.0;
//   R3.n.i = 0.0;
//   R3.p.v = comp1.p.v;
//   R3.p.v = comp2.p.v;
// end RefinedSimpleCircuit;
// endResult
