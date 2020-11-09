// name: ConstantDeclType
// keywords: constant
// status: correct
// cflags: -d=-newInst
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
