// name: ModifierRedeclare
// keywords: modifier, redeclare, replaceable
// status: correct
//
// Tests redeclarations
//

class A
  parameter Real x;
end A;

class B
  parameter Real x = 3.14, y;
end B;

class C
  replaceable A a(x = 1.0);
end C;

class D
  extends C(redeclare B a(y = 2.0));
end D;

// Result:
// class D
//   parameter Real a.x = 1.0;
//   parameter Real a.y = 2.0;
// end D;
// endResult
