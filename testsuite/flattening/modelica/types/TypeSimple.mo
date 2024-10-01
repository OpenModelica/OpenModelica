// name: TypeSimple
// keywords: type
// status: correct
//
// Tests simple type declaration
//

type MyType = Integer;

model TypeSimple
  MyType mt;
equation
  mt = 2;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TypeSimple;

// Result:
// class TypeSimple
//   Integer mt;
// equation
//   mt = 2;
// end TypeSimple;
// endResult
