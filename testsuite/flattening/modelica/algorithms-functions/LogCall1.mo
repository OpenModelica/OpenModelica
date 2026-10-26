// name:     LogCall1
// keywords: external function, equation
// status:   correct
//
// Drmodelica:
//

function mylog "Natural logarithm"
  input Real x;
  output Real y;
  external "C" y=log(x);
end mylog;

model LogCall1
  Real res;
equation
  res = mylog(100);
end LogCall1;


// Result:
// class LogCall1
//   Real res;
// equation
//   res = log(100.0);
// end LogCall1;
// endResult
