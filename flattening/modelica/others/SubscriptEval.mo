// name:     SubscriptEval
// keywords: subscripts
// status:   correct
//
// Checks that subscripts are evaluated correctly.
//

model SubscriptEval
  input Integer n;
  parameter Integer c = 1;
  Real r[1,1,1];
equation
  r[c,n,c] = 2.0;
end SubscriptEval;

// Result:
// class SubscriptEval
//   input Integer n;
//   parameter Integer c = 1;
//   Real r[1,1,1];
// equation
//   r[1,n,c] = 2.0;
// end SubscriptEval;
// endResult
