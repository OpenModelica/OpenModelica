// name: InheritancePublic
// keywords: inheritance
// status: correct
//
// Tests public inheritance
//

class A
  parameter Real a(fixed = false);
end A;

class B
  public extends A;
end B;

// Result:
// class B
//   parameter Real a(fixed = false);
// end B;
// endResult
