// name: WhenClocked1
// keywords:
// status: correct
// cflags: -d=newInst
//

model WhenClocked1
  Real x, y;
equation
  when Clock(0.1) then
    x + y = 0;
    x - y = 0;
  end when;
end WhenClocked1;

// Result:
// class WhenClocked1
//   Real x;
//   Real y;
// equation
//   when Clock(0.1) then
//     x + y = 0.0;
//     x - y = 0.0;
//   end when;
// end WhenClocked1;
// endResult
