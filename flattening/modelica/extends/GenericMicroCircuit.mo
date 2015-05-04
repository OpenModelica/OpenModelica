// name:     MicroCircuitValid
// keywords: <insert keywords here>
// status:   correct
//
// Dymola 5.2a gives back "Error: Type CompType did not extend from basic types."
// But this should be correct according to the specification?
//
// Drmodelica:
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

  model TempResistor
    extends Resistor;
    Real Temp;
    Real RT;
  end TempResistor;

  model TempResistor2
    extends TempResistor;
    Real Temp2;
  end TempResistor;

  model Resistor2
    extends Resistor;
    Real R2;
  end TempResistor;

  class GenMicroCircuit2
    replaceable type CompType = Resistor extends TwoPin;
    replaceable CompType comp1;
  end GenMicroCircuit2;

  class CapacitorMicroCircuit = GenMicroCircuit2 (redeclare type CompType =
          Capacitor);

  class GenCapacitorMicroCircuit = GenMicroCircuit2 (redeclare replaceable type
         CompType = TempCapacitor);

  class MicroCircuit2
    replaceable TempResistor R1 extends Resistor;
  end MicroCircuit2;

  class MicroCircuit3 = MicroCircuit2 (R1(R=20));

  class MicroCircuit3expanded
    replaceable TempResistor R1(R=20) extends Resistor(R=20);
  end MicroCircuit3expanded;

  class MicroCircuit4
    replaceable TempResistor R1 extends Resistor(R=30);
  end MicroCircuit4;

  class MicroCircuit5 = MicroCircuit4 (redeclare replaceable TempResistor2 R1
         extends Resistor2);

  class MicroCircuit5expanded
    replaceable TempResistor2 R1(R=30) extends Resistor2(R=30);
  end MicroCircuit5expanded;

  class ATest
    GenMicroCircuit2 genmc2;
    MicroCircuit2 mc2;
    MicroCircuit3 mc3;
    MicroCircuit3expanded mc3e;
    MicroCircuit4 mc4;
    MicroCircuit5 mc5;
    MicroCircuit5expanded mc5e;
  end ATest;



//Have not got a flattended version yet...
