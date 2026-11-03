// name: InheritanceDiamond.mo
// keywords: inheritance
// status: correct
//
// Tests diamond inheritance
//

model SuperBase
  parameter Real superReal;
end SuperBase;

model Base1
  extends SuperBase(superReal = 2.0);
  parameter Real baseReal1;
end Base1;

model Base2
  extends SuperBase(superReal = 2.0);
  parameter Real baseReal2;
end Base2;

model InheritanceDiamond
  extends Base1(baseReal1 = 2.0);
  extends Base2(baseReal2 = 3.0);
  parameter Real finalReal = 4.0;
end InheritanceDiamond;

// Result:
// class InheritanceDiamond
//   parameter Real superReal = 2.0;
//   parameter Real baseReal1 = 2.0;
//   parameter Real baseReal2 = 3.0;
//   parameter Real finalReal = 4.0;
// end InheritanceDiamond;
// endResult
