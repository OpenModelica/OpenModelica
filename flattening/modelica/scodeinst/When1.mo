// name: When1
// keywords:
// status: correct
// cflags: -d=newInst
//

model When1
  Real x;
equation
  when time > 1 then
    reinit(x, 2.0);
  end when;
end When1;

// Result:
// class When1
//   Real x;
// equation
//   when time > 1.0 then
//     reinit(x, 2.0);
//   end when;
// end When1;
// endResult
