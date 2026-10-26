// name:     StatementCall
// keywords: multiple results, algorithm
// status:   correct
//
// Computes cartesian coordinates of a point
//
// Drmodelica: 9.2 Multiple Results (p. 302)
//
function PointOnCircle
  input Real angle "Angle in radians";
  input Real radius;
  output Real x; // 1:st result formal parameter
  output Real y; // 2:nd result formal parameter
algorithm
  x := radius*cos(angle);
  y := radius*sin(angle);
end PointOnCircle;

class StatementCall
  Real height, velocity;
algorithm
  (height, velocity) := PointOnCircle(1.2, 2);
end StatementCall;

// class StatementCall
// Real px;
// Real py;
// algorithm
//   (px, py) := PointOnCircle(1.2,2.0);
// end StatementCall;
