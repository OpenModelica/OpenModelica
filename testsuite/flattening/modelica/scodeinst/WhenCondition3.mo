// name: WhenCondition3
// keywords:
// status: correct
//
//

model WhenCondition3
  Real x;
equation
  when time > 0 then
    x = 1.0;
  end when;
end WhenCondition3;

// Result:
// class WhenCondition3
//   Real x;
// equation
//   when time > 0.0 then
//     x = 1.0;
//   end when;
// end WhenCondition3;
// endResult
