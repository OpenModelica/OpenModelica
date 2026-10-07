// name: ParameterDeclType
// keywords: parameter
// status: correct
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
// [flattening/modelica/declarations/ParameterDeclType.mo:9:3-9:34:writable] Warning: Components are deprecated in class.
//
// endResult
