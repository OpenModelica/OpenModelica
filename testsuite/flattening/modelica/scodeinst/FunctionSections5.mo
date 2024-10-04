// name: FunctionSections5
// keywords:
// status: correct
//
//

partial function base_f
  input Real x;
  output Real y;
external "C";
end base_f;

function f
  extends base_f;
end f;

model FunctionSections5
  Real x = f(time);
end FunctionSections5;

// Result:
// function f
//   input Real x;
//   output Real y;
//
//   external "C" y = base_f(x);
// end f;
//
// class FunctionSections5
//   Real x = f(time);
// end FunctionSections5;
// endResult
