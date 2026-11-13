// name: TypeExtends4
// keywords:
// status: correct
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
end TypeExtends4;

// Result:
// class TypeExtends4
//   Real a(unit = "V");
//   Real b(unit = "V");
//   Real c(unit = "V", start = 1.0);
// end TypeExtends4;
// endResult
