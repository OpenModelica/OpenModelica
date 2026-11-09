// name:     Function6
// keywords: function,type
// status:   correct
//
// This tests basic function functionality
//
// OBS!
// The function f should be represented in the flatmodelica.

function f
  input Real x;
  output Real r;
algorithm
  r := 2.0 * x;
end f;

model Function6
  Real x;
  Integer z;
equation
  x = f(z);
end Function6;

// Result:
// function f
//   input Real x;
//   output Real r;
// algorithm
//   r := 2.0 * x;
// end f;
//
// class Function6
//   Real x;
//   Integer z;
// equation
//   x = f(/*Real*/(z));
// end Function6;
// endResult
