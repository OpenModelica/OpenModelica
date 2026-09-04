// name:     NoEvent2
// keywords: noEvent
// status:   correct
//
//  The noEvent operator
//

function f
  input Real x;
  output Real y = x;
  output Real z = x;
end f;

model NoEvent2
  Real x = time, y, z;
equation
  (y, z) = noEvent(f(x));
end NoEvent2;

// Result:
// function f
//   input Real x;
//   output Real y = x;
//   output Real z = x;
// end f;
//
// class NoEvent2
//   Real x = time;
//   Real y;
//   Real z;
// equation
//   (y, z) = noEvent(f(x));
// end NoEvent2;
// endResult
