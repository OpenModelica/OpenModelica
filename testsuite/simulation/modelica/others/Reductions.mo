// name:     Reductions
// keywords: reduction
// status:   correct
//
// Test reduction expression.
// Fix for bug #1136: http://openmodelica.ida.liu.se:8080/cb/issue/1136?navigation=true
//
model Reductions
  Real x,y,z,w;
  Real erx, ery, erz, erw;
  parameter Integer n = 5;
equation
  // Normal reductions
  x = sum(3.0*i for i in 1:n);
  y = min(i^2 for i in -n:n);
  z = max(i^2 for i in -n:n);
  w = product(i for i in 1:n);

  // Reduction of empty real vector
  erx = sum(i for i in 1.0:0.0);
  ery = min(i for i in 1.0:0.0);
  erz = max(i for i in 1.0:0.0);
  erw = product(i for i in 1.0:0.0);
end Reductions;

// class Reductions
// Real x;
// Real y;
// Real z;
// Real w;
// parameter Integer n = 5;
// equation
//   x = <reduction>sum(3.0 * Real(i) for i in 1:n);
//   y = Real(<reduction>min(i ^ 2 for i in -n:n));
//   z = Real(<reduction>max(i ^ 2 for i in -n:n));
//   w = Real(<reduction>product(i for i in 1:n));
//   erx = 0.0;
//   ery = 1e+60;
//   erz = -1e+60;
//   erw = 1.0;
// end Reductions;
