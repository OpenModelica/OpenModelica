// name: InheritanceMultiple
// keywords: inheritance:
// status: correct
//
// tests multiple inheritance
//

model Base1
  parameter Real baseReal1;
end Base1;

model Base2
  parameter Real baseReal2;
end Base2;

model InheritanceMultiple
  extends Base1(baseReal1 = 2.0);
  extends Base2(baseReal2 = 3.0);
  parameter Real finalReal(fixed = false);
end InheritanceMultiple;

// Result:
// class InheritanceMultiple
//   parameter Real baseReal1 = 2.0;
//   parameter Real baseReal2 = 3.0;
//   parameter Real finalReal(fixed = false);
// end InheritanceMultiple;
// endResult
