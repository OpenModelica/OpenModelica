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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end InheritanceMultiple;

// Result:
// class InheritanceMultiple
//   parameter Real baseReal1 = 2.0;
//   parameter Real baseReal2 = 3.0;
//   parameter Real finalReal;
// end InheritanceMultiple;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
