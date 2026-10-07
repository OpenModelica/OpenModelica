// name: ClockTest
// keywords: synchronous features
// status: correct

model ClockTest
  Clock c1;
  Clock c2 = Clock();
  Clock c3 = Clock(2.4);
  Clock c4 = Clock(2);
  Clock c5 = Clock(3,4);
  Clock c6;
  Clock c7 = Clock(c5, "ExplicitEuler");
equation
  c6 = Clock(time > 0.2, 0.1);
end ClockTest;

// Result:
// class ClockTest
//   Clock c1;
//   Clock c2 = Clock();
//   Clock c3 = Clock(2.4);
//   Clock c4 = Clock(2, 1);
//   Clock c5 = Clock(3, 4);
//   Clock c6;
//   Clock c7 = Clock(c5, "ExplicitEuler");
// equation
//   c6 = Clock(time > 0.2, 0.1);
// end ClockTest;
// endResult
