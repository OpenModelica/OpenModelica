// name: InheritanceDiamond.mo
// keywords: inheritance
// status: correct
//
// Tests diamond inheritance
//

class SuperBase
  parameter Real superReal;
end SuperBase;

class Base1
  extends SuperBase(superReal = 2.0);
  parameter Real baseReal1;
end Base1;

class Base2
  extends SuperBase(superReal = 3.0);
  parameter Real baseReal2;
end Base2;

class InheritanceDiamond
  extends Base1(baseReal1 = 2.0);
  extends Base2(baseReal2 = 3.0);
  parameter Real finalReal;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end InheritanceDiamond;

// Result:
// class InheritanceDiamond
//   parameter Real superReal = 2.0;
//   parameter Real baseReal1 = 2.0;
//   parameter Real baseReal2 = 3.0;
//   parameter Real finalReal;
// end InheritanceDiamond;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
