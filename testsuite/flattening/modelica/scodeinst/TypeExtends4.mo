// name: TypeExtends4
// keywords:
// status: correct
//
// Checks that the modifiers of a short type definition are kept when a long
// type definition extends it.
//

type A = Real(unit = "V");

type B
  extends A;
end B;

type C
  extends A(start = 1);
end C;

model TypeExtends4
  A a;
  B b;
  C c;
  B b2(start = 2);
end TypeExtends4;

// Result:
// class TypeExtends4
//   Real a(unit = "V");
//   Real b(unit = "V");
//   Real c(unit = "V", start = 1.0);
//   Real b2(unit = "V", start = 2.0);
// end TypeExtends4;
// endResult
