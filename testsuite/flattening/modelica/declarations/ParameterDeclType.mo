// name: ParameterDeclType
// keywords: parameter
// status: correct
// cflags: -d=-newInst
//
// Tests the parameter prefix on a regular type
//

class ParameterDeclType
  parameter Real rParameter = 1.0;
end ParameterDeclType;

// Result:
// class ParameterDeclType
//   parameter Real rParameter = 1.0;
// end ParameterDeclType;
// endResult
