// name: InheritanceSeveral
// keywords: inheritance
// status: correct
//
// Tests simple inheritance in several steps
//

class A
  parameter Real a(fixed = false);
end A;

class B
  extends A;
  parameter Real b(fixed = false);
end B;

class C
  extends B;
end C;

// Result:
// class C
//   parameter Real a(fixed = false);
//   parameter Real b(fixed = false);
// end C;
// endResult
