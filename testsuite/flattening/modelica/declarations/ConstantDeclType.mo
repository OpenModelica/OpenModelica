// name: ConstantDeclType
// keywords: constant
// status: correct
//
// Tests the constant prefix on a regular type
//

model ConstantDeclType
  constant Real rConst = 2.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ConstantDeclType;

// Result:
// class ConstantDeclType
//   constant Real rConst = 2.0;
// end ConstantDeclType;
// endResult
