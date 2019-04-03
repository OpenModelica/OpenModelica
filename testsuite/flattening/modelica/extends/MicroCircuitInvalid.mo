// name:     MicroCircuitInvalid
// keywords: <insert keywords here>
// status:   incorrect
//
// This test should be incorrect, but currently, it is incorrect because of the
// wrong reason. When MicroCircuitValid works, we can if check this test is correct.

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


class MicroCircuit
  replaceable Resistor comp1;
end MicroCircuit;

class TempMicroCircuit = MicroCircuit(redeclare TempResistor comp1);

class GenMicroCircuit
  replaceable type CompType = Resistor;
  replaceable CompType comp1;
end GenMicroCircuit;

class InductorMicroCircuit =
  GenMicroCircuit(redeclare type CompType = Inductor);



// Result:
// Error processing file: MicroCircuitInvalid.mo
// [flattening/modelica/extends/MicroCircuitInvalid.mo:84:29-84:53:writable] Error: Class specialization violation: .Inductor is a model, not a type.
// Error: Error occurred while flattening model InductorMicroCircuit
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
