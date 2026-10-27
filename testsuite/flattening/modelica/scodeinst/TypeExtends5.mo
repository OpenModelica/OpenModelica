// name: TypeExtends5
// keywords:
// status: correct
//
// Checks that the modifiers of long type definitions are split correctly when
// applied to arrays.
//

type A = Real(unit = "V");

type B
  extends A;
end B;

type B2
  extends B(start = 2);
end B2;

type C
  extends Real(start = 1);
end C;

type C2
  extends C;
end C2;

type Alias = Real[3](each unit = "V");

type Alias2
  extends Alias(start = {1, 2, 3});
end Alias2;

model TypeExtends5
  B b[2];
  B2 b2[2, 2];
  C2 c2[2];
  Alias2 a2[2];
end TypeExtends5;

// Result:
// class TypeExtends5
//   Real b[1](unit = "V");
//   Real b[2](unit = "V");
//   Real b2[1,1](unit = "V", start = 2.0);
//   Real b2[1,2](unit = "V", start = 2.0);
//   Real b2[2,1](unit = "V", start = 2.0);
//   Real b2[2,2](unit = "V", start = 2.0);
//   Real c2[1](start = 1.0);
//   Real c2[2](start = 1.0);
//   Real a2[1,1](unit = "V", start = 1.0);
//   Real a2[1,2](unit = "V", start = 2.0);
//   Real a2[1,3](unit = "V", start = 3.0);
//   Real a2[2,1](unit = "V", start = 1.0);
//   Real a2[2,2](unit = "V", start = 2.0);
//   Real a2[2,3](unit = "V", start = 3.0);
// end TypeExtends5;
// endResult
