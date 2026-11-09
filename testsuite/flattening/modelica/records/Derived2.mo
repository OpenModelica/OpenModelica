// name:     Record Derived 2
// keywords: record
// status:   correct

record BaseProps_Tpoly "Fluid state record"
  Real T "temperature";
  Real p "pressure";
end BaseProps_Tpoly;

model M
  constant Real T = 1.0;
  constant Real p = 2.0;
  ThermodynamicState res;
  replaceable record ThermodynamicState end ThermodynamicState;
end M;

model N
  extends M(redeclare record ThermodynamicState=BaseProps_Tpoly, res = ThermodynamicState(T = T, p = p));
end N;

// Result:
// class N
//   constant Real T = 1.0;
//   constant Real p = 2.0;
//   Real res.T = 1.0 "temperature";
//   Real res.p = 2.0 "pressure";
// end N;
// endResult
