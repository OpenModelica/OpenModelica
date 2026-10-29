// name: TypeClass1
// keywords: type
// status: correct
//
// Tests type declaration from a legal class
//

class LegalClass
  extends Integer;
end LegalClass;

type LegalType = LegalClass;

model TypeClass1
  LegalType lt;
equation
  lt = 1;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TypeClass1;

// Result:
// class TypeClass1
//   Integer lt;
// equation
//   lt = 1;
// end TypeClass1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
