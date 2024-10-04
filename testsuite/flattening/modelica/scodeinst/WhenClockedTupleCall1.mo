// name: WhenClockedTupleCall1
// keywords:
// status: correct
//

function f
  output Real x = 1;
  output Real y = 2;
end f;

model WhenClockedTupleCall1
  Real x, y;
equation
  when Clock() then
    (x, y) = f();
  end when;
end WhenClockedTupleCall1;

// Result:
// class WhenClockedTupleCall1
//   Real x;
//   Real y;
// equation
//   when Clock() then
//     x = 1.0;
//     y = 2.0;
//   end when;
// end WhenClockedTupleCall1;
// endResult
