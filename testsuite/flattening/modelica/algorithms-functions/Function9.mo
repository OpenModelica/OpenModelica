// name:     Function9
// keywords: function
// status:   correct
//
// This tests for illegal parts of a function definition.
//

function f
  input Real x;
  output Real r;
protected
  Real nottoomuch;
algorithm
  r := 2.0 * x;
end f;

model Function9
  Real x, z;
equation
  x = f(z);
end Function9;

// Result:
// function f
//   input Real x;
//   output Real r;
//   protected Real nottoomuch;
// algorithm
//   r := 2.0 * x;
// end f;
//
// class Function9
//   Real x;
//   Real z;
// equation
//   x = f(z);
// end Function9;
// endResult
