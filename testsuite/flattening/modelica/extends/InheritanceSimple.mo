// name: InheritanceSimple
// keywords: inheritance
// status: correct
//
// Tests simple inheritance
//

class A
  parameter Real a;
end A;

class B
  extends A;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end B;

// Result:
// class B
//   parameter Real a;
// end B;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
