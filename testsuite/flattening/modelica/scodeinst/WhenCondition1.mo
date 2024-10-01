// name: WhenCondition1
// keywords:
// status: correct
//
//

model WhenCondition1
  Boolean b;
  Real x;
equation
  when b then
    x = 1.0;
  end when;
end WhenCondition1;

// Result:
// class WhenCondition1
//   Boolean b;
//   Real x;
// equation
//   when b then
//     x = 1.0;
//   end when;
// end WhenCondition1;
// endResult
