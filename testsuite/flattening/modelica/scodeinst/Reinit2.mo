// name: Reinit2
// keywords:
// status: correct
// cflags: -d=newInst
//

model Reinit2
  Real x[3];
equation
  when time > 1 then
    reinit(x, {1, 2, 3});
  end when;
end Reinit2;

// Result:
// class Reinit2
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   when time > 1.0 then
//     reinit(x, {1.0, 2.0, 3.0});
//   end when;
// end Reinit2;
// endResult
