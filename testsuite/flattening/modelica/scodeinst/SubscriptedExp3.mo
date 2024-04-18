// name: SubscriptedExp3
// status: correct
// cflags: -d=newInst
//
//

model SubscriptedExp3
  Real y;
equation
  ({1, 2, 3})[3] = y;
end SubscriptedExp3;

// Result:
// class SubscriptedExp3
//   Real y;
// equation
//   3.0 = y;
// end SubscriptedExp3;
// endResult
