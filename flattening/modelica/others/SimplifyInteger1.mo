// name:     SimplifyInteger1
// keywords: simplify #4847
// status:   correct
//
//

model SimplifyInteger1
  Integer x;
  Integer y1 = x + x;
  Integer y2 = x + x + x;
  Integer y3 = x + x + x + x;
  Integer y4 = x * x;
  Integer y5 = x * x * x;
  Integer y6 = x * x * x * x;
  Integer y7 = 2*x + 6*x;
end SimplifyInteger1;

// Result:
// class SimplifyInteger1
//   Integer x;
//   Integer y1 = 2 * x;
//   Integer y2 = 3 * x;
//   Integer y3 = 4 * x;
//   Integer y4 = x * x;
//   Integer y5 = x * x * x;
//   Integer y6 = x * x * x * x;
//   Integer y7 = 8 * x;
// end SimplifyInteger1;
// endResult
