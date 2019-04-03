// name: When5
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When5
  Real x;
equation
  when time > 0 then
    x = 1;
  elsewhen time > 1 then
    x = 2;
  end when;
end When5;

// Result:
// class When5
//   Real x;
// equation
//   when time > 0.0 then
//     x = 1.0;
//   elsewhen time > 1.0 then
//     x = 2.0;
//   end when;
// end When5;
// endResult
