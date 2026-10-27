// name: ConstantDeclType
// keywords: constant
// status: correct
//
// Tests the constant prefix on a regular type
//

model ConstantDeclType
  constant Real rConst = 2.0;
end ConstantDeclType;

// Result:
// class ConstantDeclType
//   constant Real rConst = 2.0;
// end ConstantDeclType;
// endResult
