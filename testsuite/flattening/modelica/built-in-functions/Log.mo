// name: Log
// keywords: log
// status: correct
//
// Tests the built-in log function
//

model Log
  Real r;
equation
  r = log(45);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Log;

// Result:
// class Log
//   Real r;
// equation
//   r = 3.8066624897703196;
// end Log;
// endResult
