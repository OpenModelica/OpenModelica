// name: SubscriptedExp1
// status: correct
//
//

model SubscriptedExp1
  Real y = ({1, 2, 3})[2];
end SubscriptedExp1;

// Result:
// class SubscriptedExp1
//   Real y = 2.0;
// end SubscriptedExp1;
// endResult
