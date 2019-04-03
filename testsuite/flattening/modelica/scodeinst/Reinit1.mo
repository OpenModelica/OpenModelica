// name: Reinit1
// keywords:
// status: correct
// cflags: -d=newInst
//

model Reinit1
  Real x;
equation
  when time > 1 then
    reinit(x, 2);
  end when;
end Reinit1;

// Result:
// class Reinit1
//   Real x;
// equation
//   when time > 1.0 then
//     reinit(x, 2.0);
//   end when;
// end Reinit1;
// endResult
