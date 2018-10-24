// name: ClockConstructor1
// keywords:
// status: correct
// cflags: -d=newInst
//

model ClockConstructor1
  Clock c1 = Clock();
  Clock c2 = Clock(1);
  Clock c3 = Clock(1, 2);
  Clock c4 = Clock(intervalCounter = 1, resolution = 2);
  Clock c5 = Clock(1.0);
  Clock c6 = Clock(interval = 2.0);
  Clock c7 = Clock(time < 1);
  Clock c8 = Clock(time < 1, 1.0);
  Clock c9 = Clock(condition = time < 1, startInterval = 0.5);
  Clock c10 = Clock(c2, "ImplicitTrapezoid");
  Clock c11 = Clock(c = c3, solverMethod = "");
end ClockConstructor1;

// Result:
// class ClockConstructor1
//   Clock c1 = Clock();
//   Clock c2 = Clock(1, 1);
//   Clock c3 = Clock(1, 2);
//   Clock c4 = Clock(1, 2);
//   Clock c5 = Clock(1.0);
//   Clock c6 = Clock(2.0);
//   Clock c7 = Clock(time < 1.0, 0.0);
//   Clock c8 = Clock(time < 1.0, 1.0);
//   Clock c9 = Clock(time < 1.0, 0.5);
//   Clock c10 = Clock(c2, "ImplicitTrapezoid");
//   Clock c11 = Clock(c3, "");
// end ClockConstructor1;
// endResult
