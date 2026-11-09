// name:     EquationCall
// keywords: multiple results, equation
// status:   correct
//
// Computes cartesian coordinates of a point
// Drmodelica: 9.2 Multiple Results (p. 302)
//

function PointOnCircle
  input Real angle "Angle in radians";
  input Real radius;
  output Real x; // 1:st result formal parameter
  output Real y; // 2:nd result formal parameter
algorithm
  x := radius*cos(angle);//Modelica.Math.cos(angle);
  y := radius*sin(angle);//Modelica.Math.sin(angle);
end PointOnCircle;

model EquationCall
  Real px, py;
equation
  (px, py) = PointOnCircle(1.2, 2);
end EquationCall;

// Result:
// class EquationCall
//   Real px;
//   Real py;
// equation
//   px = 0.7247155089533472;
//   py = 1.8640781719344526;
// end EquationCall;
// endResult
