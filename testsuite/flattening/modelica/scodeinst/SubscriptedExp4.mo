// name: SubscriptedExp4
// status: correct
// cflags: -d=newInst
//
//

model SubscriptedExp4
  Real x[:] = {1, 2, 3};
  Integer n;
  Real y = ({1, 2 ,3})[n];
  Real z = (x)[n];
end SubscriptedExp4;

// Result:
// class SubscriptedExp4
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Integer n;
//   Real y = {1.0, 2.0, 3.0}[n];
//   Real z = x[n];
// equation
//   x = {1.0, 2.0, 3.0};
// end SubscriptedExp4;
// endResult
