// name: InheritanceMultiple
// keywords: inheritance:
// status: correct
//
// tests multiple inheritance
//

class Base1
  parameter Real baseReal1;
end Base1;

class Base2
  parameter Real baseReal2;
end Base2;

class InheritanceMultiple
  extends Base1(baseReal1 = 2.0);
  extends Base2(baseReal2 = 3.0);
  parameter Real finalReal;
end InheritanceMultiple;

// Result:
// class InheritanceMultiple
//   parameter Real baseReal1 = 2.0;
//   parameter Real baseReal2 = 3.0;
//   parameter Real finalReal;
// end InheritanceMultiple;
// endResult
