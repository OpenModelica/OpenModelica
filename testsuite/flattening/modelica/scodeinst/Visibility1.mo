// name: Visibility1
// keywords:
// status: correct
//

model Visibility1
  Real x;
protected
  Real y;
equation
  y = x;
end Visibility1;

// Result:
// class Visibility1
//   Real x;
//   protected Real y;
// equation
//   y = x;
// end Visibility1;
// endResult
