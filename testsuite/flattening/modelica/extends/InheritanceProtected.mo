// name: InheritanceProtected
// keywords: inheritance
// status: correct
//
// Tests protected inheritance
//

class A
  parameter Real a;
end A;

class B
  protected extends A;
end B;

// Result:
// class B
//   protected parameter Real a;
// end B;
// endResult
