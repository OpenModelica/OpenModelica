// name: EventFunctions
// keywords: functions, builtin
// status: correct
//
// Testing built in event triggering mathematical functions
//

model EventFunctions
  Real r1 = div(45, 4);
  Real r2 = mod(8, 3);
  Real r3 = rem(27, 6);
  Real r4 = ceil(4.5);
  Real r5 = floor(4.5);
  Real r6 = integer(4.5);
end EventFunctions;

// Result:
// class EventFunctions
//   Real r1 = 11.0;
//   Real r2 = 2.0;
//   Real r3 = 3.0;
//   Real r4 = 5.0;
//   Real r5 = 4.0;
//   Real r6 = 4.0;
// end EventFunctions;
// endResult
