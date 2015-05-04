// name:     RefinedSimpleCircuitInvalid
// keywords: <insert keywords here>
// status:   incorrect
//
//
// Sometimes it can be useful to allow a more general constraining type of
// a class parameter, e.g. TwoPin instead of Resistor for the formal class
// parameters and components comp1 and comp2 below. This allows replacement
// by another kind of electrical component than a resistor in the circuit.
//
// Drmodelica: 4.4 Parameterized Generic Classes (p. 133)
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
    //extends TwoPin; S
    //Since Capacitor is not inherited from TwoPin, the model should fail

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

// Result:
// Error processing file: RefinedSimpleCircuitInvalid.mo
// [flattening/modelica/types/RefinedSimpleCircuitInvalid.mo:63:5-63:17:writable] Error: Variable i not found in scope Capacitor$comp1.
// Error: Error occurred while flattening model RefinedSimpleCircuit
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
