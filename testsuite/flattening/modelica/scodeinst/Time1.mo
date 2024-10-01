// name: Time1
// keywords:
// status: correct
//

model Time1
  Real x = time;
  Real y;
equation
  y = time;
end Time1;

// Result:
// class Time1
//   Real x = time;
//   Real y;
// equation
//   y = time;
// end Time1;
// endResult
