// name:     Lookup6
// keywords: scoping
// status:   correct
//
// The constant 'a' is hidden in class 'B' after the declaration
// of 'B.a'.
//

model Lookup6
  constant Real a = 3.0;
  model B
    Real a;
  equation
    a = -a;
  end B;
  B b;
end Lookup6;

// Result:
// class Lookup6
//   constant Real a = 3.0;
//   Real b.a;
// equation
//   b.a = -b.a;
// end Lookup6;
// endResult
