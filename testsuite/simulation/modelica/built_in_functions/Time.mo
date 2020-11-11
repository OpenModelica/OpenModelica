// name: Time
// keywords: time
// status: correct
// cflags: -d=-newInst
//
// Testing the built-in variable time
//

model Time
  Real x;
equation
  x = time;
end Time;

// class Time
// Real x;
// equation
//   x = time;
// end Time;
