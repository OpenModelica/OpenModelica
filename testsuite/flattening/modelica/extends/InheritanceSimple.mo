// name: InheritanceSimple
// keywords: inheritance
// status: correct
//
// Tests simple inheritance
//

class A
  parameter Real a(fixed = false);
end A;

class B
  extends A;
end B;

// Result:
// class B
//   parameter Real a(fixed = false);
// end B;
// endResult
