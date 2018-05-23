// name: When4
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When4
  Real x, y;
equation
  when time > 0 then
    x = 1;
    y = 2;
  end when;
end When4;

// Result:
// class When4
//   Real x;
//   Real y;
// equation
//   when time > 0.0 then
//     x = 1.0;
//     y = 2.0;
//   end when;
// end When4;
// endResult
