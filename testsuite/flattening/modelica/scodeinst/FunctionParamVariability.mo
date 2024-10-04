// name: FunctionParamVariability
// keywords:
// status: correct
//
// Checks that declaring a function parameter constant/parameter has no impact
// on the function, since variability prefixes have no semantic meaning for
// function parameters.
//

function f
  constant input Real x = 1.0;
  parameter output Real y = x + x;
end f;

model FunctionParamVariability
  Real x = f(time);
end FunctionParamVariability;

// Result:
// function f
//   input Real x = 1.0;
//   output Real y = x + x;
// end f;
//
// class FunctionParamVariability
//   Real x = f(time);
// end FunctionParamVariability;
// endResult
