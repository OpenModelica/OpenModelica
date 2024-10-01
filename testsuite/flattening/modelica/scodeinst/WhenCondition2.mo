// name: WhenCondition2
// keywords:
// status: correct
//
//

model WhenCondition2
  Boolean b;
  Real x;
equation
  when {b, initial()} then
    x = 1.0;
  end when;
end WhenCondition2;

// Result:
// class WhenCondition2
//   Boolean b;
//   Real x;
// equation
//   when {b, initial()} then
//     x = 1.0;
//   end when;
// end WhenCondition2;
// endResult
