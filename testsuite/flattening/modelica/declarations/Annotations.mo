// name:     Annotations
// keywords: declaration annotations comments
// status:   correct
// cflags:   +showAnnotations
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
//   annotation(key = value);
// end c;
// endResult
