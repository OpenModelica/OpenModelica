// name: Time
// keywords: time
// status: correct
//
// Testing the built-in variable time
//

model Time
  Real x;
equation
  x = time;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Time;

// class Time
// Real x;
// equation
//   x = time;
// end Time;
