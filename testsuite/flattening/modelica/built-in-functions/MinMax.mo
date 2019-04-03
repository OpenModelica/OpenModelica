// name:     Min & Max
// keywords: builtin functions min max
// status:   correct
//
// Usage of the min and max functions
model MinMax
  Real x[max(n,m)];
  Real y[max([n,m])];
  parameter Integer n=min(m,3);
  parameter Integer m = 4;
  constant Boolean bemptyarr[0]=fill(true, 0);
  constant Boolean b1 = min(true,false);
  constant Boolean b2 = min({true,true,false});
  constant Boolean b3 = min(bemptyarr);
  constant Boolean b4 = max(true,false);
  constant Boolean b5 = max({true,true,false});
  constant Boolean b6 = max(bemptyarr);
equation
  x= fill(1.0,max(n,m));
end MinMax;
// Result:
// class MinMax
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   parameter Integer n = min(m, 3);
//   parameter Integer m = 4;
//   constant Boolean b1 = false;
//   constant Boolean b2 = false;
//   constant Boolean b3 = true;
//   constant Boolean b4 = true;
//   constant Boolean b5 = true;
//   constant Boolean b6 = false;
// equation
//   x[1] = 1.0;
//   x[2] = 1.0;
//   x[3] = 1.0;
//   x[4] = 1.0;
// end MinMax;
// endResult
