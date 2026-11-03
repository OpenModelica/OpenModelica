// name: BindingCycle1
// keywords: parameter cycle
// status: correct
//
// Checks that a parameter that breaks a binding cycle is evaluated everywhere,
// not only in the bindings of the cycle.
//

model BindingCycle1
  parameter Boolean b = true;
  parameter Real x = if b then 1 else y;
  parameter Real y = if b then 2*x else 2;
  Real z = if b then time else -time;
end BindingCycle1;

// Result:
// class BindingCycle1
//   final parameter Boolean b = true;
//   parameter Real x = 1.0;
//   parameter Real y = 2.0 * x;
//   Real z = time;
// end BindingCycle1;
// endResult
