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
  parameter Integer m(min = 1) = 2;
  input Modelica.SIunits.Volume[n] v;
end myPartialModel;

partial model mySecondPartialModel
  parameter Integer n(min = 1) = 3;
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
//   parameter Integer n(min = 1) = 3;
//   parameter enumeration(divisionType1, divisionType2) myDivision = MyType.divisionType1;
//   parameter Integer m(min = 1) = -1 + n;
//   input Real v[1];
//   input Real v[2];
//   input Real v[3];
//   parameter Real x[1] = lengths[1];
//   parameter Real x[2] = lengths[2];
//   parameter Real x[3] = lengths[3];
//   parameter Real y[1] = areas[1];
//   parameter Real y[2] = areas[2];
//   parameter Real y[3] = areas[3];
//   parameter Real z[1] = volumes[1];
//   parameter Real z[2] = volumes[2];
//   parameter Real z[3] = volumes[3];
//   parameter Real a = 1.0;
//   parameter Real b = 1.0;
//   final parameter Real c = a ^ 2.0;
//   final parameter Real areas[1] = c / /*Real*/(n);
//   final parameter Real areas[2] = c / /*Real*/(n);
//   final parameter Real areas[3] = c / /*Real*/(n);
//   final parameter Real lengths[1] = if myDivision == MyType.divisionType1 then 0.5 * b / /*Real*/(-1 + n) else b / /*Real*/(n);
//   final parameter Real lengths[2] = if myDivision == MyType.divisionType1 then b / /*Real*/(-1 + n) else b / /*Real*/(n);
//   final parameter Real lengths[3] = if myDivision == MyType.divisionType1 then 0.5 * b / /*Real*/(-1 + n) else b / /*Real*/(n);
//   final parameter Real volumes[1] = areas[1] * lengths[1];
//   final parameter Real volumes[2] = areas[2] * lengths[2];
//   final parameter Real volumes[3] = areas[3] * lengths[3];
// equation
//   v = {z[1], z[2], z[3]};
// end Modification17;
// endResult
