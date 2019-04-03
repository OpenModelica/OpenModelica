// name: InheritanceSeveral
// keywords: inheritance
// status: correct
//
// Tests simple inheritance in several steps
//

class A
  parameter Real a;
end A;

class B
  extends A;
  parameter Real b;
end B;

class C
  extends B;
end C;

// Result:
// class C
//   parameter Real a;
//   parameter Real b;
// end C;
// endResult
