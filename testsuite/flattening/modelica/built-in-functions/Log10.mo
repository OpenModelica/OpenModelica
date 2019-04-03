// name: Log10
// keywords: log10
// status: correct
//
// Tests the built-in log10 function
//

model Log10
  Real r;
equation
  r = log10(45);
end Log10;

// Result:
// class Log10
//   Real r;
// equation
//   r = 1.6532125137753437;
// end Log10;
// endResult
