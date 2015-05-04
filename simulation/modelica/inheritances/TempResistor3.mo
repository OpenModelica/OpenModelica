// name:     TempResistor3
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK ON THIS FILE HAS TO BE DONE!
//
// Drmodelica: 4.5 Design a Class to be Extended (p. 137)
//
type Voltage = Real(Unit = "V");

type Current = Real(Unit = "A");

connector Pin
  Voltage v;
  flow Current i;
end Pin;

model Resistor3  "Electrical Resistor"
  Pin p, n;
  Voltage v;
  Current i;
  parameter Real R(unit = "Ohm")   "Resistance";

  replaceable class ResistorEquation
    equation
      v = i*R;
  end ResistorEquation;

end Resistor3;

model TempResistor3 "Temperature dependent electrical resistor"
  extends Resistor3(
    redeclare class ResistorEquation
      equation
        v = i*(R + RT*(Temp - Tref));
    end ResistorEquation);

  parameter Real RT(unit = "Ohm/degC") = 0   "Temp. dependent Resistance.";
  parameter Real Tref(unit = "degC") = 20    "Reference temperature";
  Real    Temp = 20            "Actual temperature";

end TempResistor3;


// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class TempResistor3
// Real p.v;
// Real p.i;
// Real n.v;
// Real n.i;
// Real v;
// Real i;
// parameter Real R(unit = "Ohm") "Resistance";
// parameter Real RT(unit = "Ohm/degC") = 0 "Temp. dependent Resistance.";
// parameter Real Tref(unit = "degC") = 20 "Reference temperature";
// Real Temp "Actual temperature";
// equation
//   Temp = 20.0;
// end TempResistor3;
