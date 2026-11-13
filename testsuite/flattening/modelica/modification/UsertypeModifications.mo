// name:     UsertypeModifications
// keywords: usertypes, modifications, arrays, extend
// status:   correct
//
// Tests that modifications on usertypes are propagated correctly
//

type Alias = Real[3](each unit = "new_bugs/fix");

type Alias2
  extends Alias(each start = 3);
end Alias2;

model AliasType
  type B = Real[4](each start=2);
  B b;
  parameter Real[4] a = zeros(4);
  Alias2 a2;
equation
  b = a;
  a2 = ones(3);
end AliasType;

// Result:
// class AliasType
//   Real b[1](start = 2.0);
//   Real b[2](start = 2.0);
//   Real b[3](start = 2.0);
//   Real b[4](start = 2.0);
//   parameter Real a[1] = 0.0;
//   parameter Real a[2] = 0.0;
//   parameter Real a[3] = 0.0;
//   parameter Real a[4] = 0.0;
//   Real a2[1](unit = "new_bugs/fix", start = 3.0);
//   Real a2[2](unit = "new_bugs/fix", start = 3.0);
//   Real a2[3](unit = "new_bugs/fix", start = 3.0);
// equation
//   b[1] = a[1];
//   b[2] = a[2];
//   b[3] = a[3];
//   b[4] = a[4];
//   a2[1] = 1.0;
//   a2[2] = 1.0;
//   a2[3] = 1.0;
// end AliasType;
// endResult
