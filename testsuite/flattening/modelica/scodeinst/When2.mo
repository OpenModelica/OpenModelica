// name: When2
// keywords:
// status: correct
// cflags: -d=newInst
//

model When2
  Real x = 1;
  Boolean b[3];
equation
  when b then
    reinit(x, 2.0);
  end when;
end When2;

// Result:
// class When2
//   Real x = 1.0;
//   Boolean b[1];
//   Boolean b[2];
//   Boolean b[3];
// equation
//   when {b[1], b[2], b[3]} then
//     reinit(x, 2.0);
//   end when;
// end When2;
// endResult
