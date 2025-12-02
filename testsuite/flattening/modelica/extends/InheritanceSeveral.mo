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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end C;

// Result:
// class C
//   parameter Real a;
//   parameter Real b;
// end C;
// endResult
