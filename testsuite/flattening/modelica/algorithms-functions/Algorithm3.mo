// name:     Algorithm3
// keywords: algorithm
// status:   correct
//
// Type checks in algorithms.
//

model Algorithm3
  Integer i=integer(time*10);
  Real x;
algorithm
  x := i;
end Algorithm3;

// Result:
// class Algorithm3
//   Integer i = integer(time * 10.0);
//   Real x;
// algorithm
//   x := /*Real*/(i);
// end Algorithm3;
// endResult
