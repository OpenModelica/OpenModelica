// name: ParameterDeclType
// keywords: parameter
// status: correct
//
// Tests the parameter prefix on a regular type
//

class ParameterDeclType
  parameter Real rParameter = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ParameterDeclType;

// Result:
// class ParameterDeclType
//   parameter Real rParameter = 1.0;
// end ParameterDeclType;
// endResult
