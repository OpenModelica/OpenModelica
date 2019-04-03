model Tearing15
  "System to test unsolvables as tVars in Cellier Algorithm"
  Real source;
  Real v1(start=7);
  Real v2(start=1);
  Real v3(start=1);
  Real v4(start=1);
  Real v5(start=1);
  Real v6(start=50);
  Real v7(start=3);

equation
  source = sin(time);
  v1*sin(v1) + v2 - 4  + source = 0;
  2*v1*sin(v1) + v2 - v3 - source +v7= 0;
  3*v1*sin(v1) - 7*v2 - 2*v3 + 3 * source *v7= 0;
  v1* sin(v1) + v2+source -v3*source -v7= 0;
  3*v2 - v4 - v5 + 2 - source/2 *v7 = 0;
  v5 + v6*sin(v6) * source +v3 = 0;
  3*v5 - v6*sin(v6) - source = 0;
end Tearing15;
