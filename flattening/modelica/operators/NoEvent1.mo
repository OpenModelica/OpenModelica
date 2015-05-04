// name:     NoEvent1
// keywords: noEvent
// status:   correct
//
//  The noEvent operator
//

model NoEvent1
  parameter Real c=1.0;
  Real x,y,z;
  Boolean b;
  Real h;
equation
  b = noEvent(x<y);
  der(h)=if noEvent(h>0) then -c*sqrt(h) else 0;
end NoEvent1;

// Result:
// class NoEvent1
//   parameter Real c = 1.0;
//   Real x;
//   Real y;
//   Real z;
//   Boolean b;
//   Real h;
// equation
//   b = noEvent(x < y);
//   der(h) = if noEvent(h > 0.0) then (-c) * sqrt(h) else 0.0;
// end NoEvent1;
// endResult
