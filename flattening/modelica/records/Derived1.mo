// name:     Record Derived 1
// keywords: record
// status:   correct

record BaseProps_Tpoly "Fluid state record"
  Real T "temperature";
  Real p "pressure";
end BaseProps_Tpoly;

model Derived1
  constant Real T = 1.0;
  constant Real p = 2.0;
  constant ThermodynamicState res = ThermodynamicState(T = T, p = p);
  record ThermodynamicState = BaseProps_Tpoly;
end Derived1;

// Result:
// function Derived1.ThermodynamicState "Automatically generated record constructor for Derived1.ThermodynamicState"
//   input Real T;
//   input Real p;
//   output ThermodynamicState res;
// end Derived1.ThermodynamicState;
//
// class Derived1
//   constant Real T = 1.0;
//   constant Real p = 2.0;
//   constant Real res.T = 1.0 "temperature";
//   constant Real res.p = 2.0 "pressure";
// end Derived1;
// endResult
