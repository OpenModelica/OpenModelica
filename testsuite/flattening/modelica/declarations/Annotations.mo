// name:     Annotations
// keywords: declaration annotations comments
// status:   correct
//
// Checks that annotations are output correctly on the flat code when
// +showAnnotations is used.
//

function f "Some comment"
  input Real x "comment";
  output Real y annotation(key = value);
algorithm
  y := x;
  annotation(key = value);
end f;

class c
  Real x "x" annotation(key = value);
equation
  x = f(time);
  annotation(key = value);
  annotation(__OpenModelica_commandLineOptions="+showAnnotations -d=-newInst");
end c;

// Result:
// function f "Some comment"
//   input Real x "comment";
//   output Real y annotation(key = value);
// algorithm
//   y := x;
//   annotation(key = value);
// end f;
//
// class c
//   Real x "x" annotation(key = value);
// equation
//   x = f(time);
//   annotation(key = value, __OpenModelica_commandLineOptions = "+showAnnotations -d=-newInst");
// end c;
// endResult
