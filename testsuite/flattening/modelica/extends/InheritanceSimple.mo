// name: InheritanceSimple
// keywords: inheritance
// status: correct
// cflags: -d=-newInst
//
// Tests simple inheritance
//

class A
  parameter Real a;
end A;

class B
  extends A;
end B;

// Result:
// class B
//   parameter Real a;
// end B;
// endResult
