// name:     Modification17
// keywords: modification
// status:   correct
//

package Modelica
  package SIunits
    type Length = Real;
    type Area = Real;
    type Volume = Real;
  end SIunits;
end Modelica;

type MyType = enumeration(divisionType1 , divisionType2 );

partial model myPartialModel
  parameter Integer n(min = 1) = 3;
  parameter Integer m(min = 1) = 2;
  input Modelica.SIunits.Volume[n] v;
end myPartialModel;

partial model mySecondPartialModel
  parameter MyType myDivision = MyType.divisionType1;
  extends myPartialModel(final m = n - 1, final v = z);
  parameter Modelica.SIunits.Length[n] x;
  parameter Modelica.SIunits.Area[n] y;
  parameter Modelica.SIunits.Volume[n] z;
end mySecondPartialModel;

model Modification17
  parameter Modelica.SIunits.Length a = 1;
  parameter Modelica.SIunits.Length b = 1;
  final parameter Modelica.SIunits.Length c = a * a;
  final parameter Modelica.SIunits.Area[n] areas = fill(c / n, n);
  final parameter Modelica.SIunits.Length[n] lengths = if n == 1 then {b} elseif myDivision == MyType.divisionType1 then cat(1, {b / (n - 1) / 2}, fill(b / (n - 1), n - 2), {b / (n - 1) / 2}) else fill(b / n, n);
  final parameter Modelica.SIunits.Volume[n] volumes = array(areas[i] * lengths[i] for i in 1:n);
  extends mySecondPartialModel(final x = lengths, final y = areas, final z = volumes);
end Modification17;

// Result:
// class Modification17
//   parameter Real a = 1.0;
//   parameter Real b = 1.0;
//   final parameter Real c = a * a;
//   final parameter Real areas[1] = c / 3.0;
//   final parameter Real areas[2] = c / 3.0;
//   final parameter Real areas[3] = c / 3.0;
//   final parameter Real lengths[1] = if myDivision == MyType.divisionType1 then b / 2.0 / 2.0 else b / 3.0;
//   final parameter Real lengths[2] = if myDivision == MyType.divisionType1 then b / 2.0 else b / 3.0;
//   final parameter Real lengths[3] = if myDivision == MyType.divisionType1 then b / 2.0 / 2.0 else b / 3.0;
//   final parameter Real volumes[1] = areas[1] * lengths[1];
//   final parameter Real volumes[2] = areas[2] * lengths[2];
//   final parameter Real volumes[3] = areas[3] * lengths[3];
//   parameter enumeration(divisionType1, divisionType2) myDivision = MyType.divisionType1;
//   final parameter Integer n(min = 1) = 3;
//   final parameter Integer m(min = 1) = 2;
//   final Real v[1];
//   final Real v[2];
//   final Real v[3];
//   final parameter Real x[1] = lengths[1];
//   final parameter Real x[2] = lengths[2];
//   final parameter Real x[3] = lengths[3];
//   final parameter Real y[1] = areas[1];
//   final parameter Real y[2] = areas[2];
//   final parameter Real y[3] = areas[3];
//   final parameter Real z[1] = volumes[1];
//   final parameter Real z[2] = volumes[2];
//   final parameter Real z[3] = volumes[3];
// equation
//   v = z;
// end Modification17;
// [flattening/modelica/modification/Modification17.mo:19:3-19:37:writable] Notification: Top-level input 'v' has a binding equation and will not be accessible as an input of the model.
//
// endResult
