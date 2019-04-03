// name: When7
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When7
  Real x;
equation
  when time > 0 then
    x = 1;
  elsewhen time > 1 then
    reinit(x, 2);
  end when;
end When7;

// Result:
// class When7
//   Real x;
// equation
//   when time > 0.0 then
//     x = 1.0;
//   elsewhen time > 1.0 then
//     reinit(x, 2.0);
//   end when;
// end When7;
// endResult
