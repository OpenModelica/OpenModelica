// name: When3
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When3
  Real x, y;
  Boolean b, b2;
equation
  when {b, b2} then
    x = y;
  end when;
end When3;

// Result:
// class When3
//   Real x;
//   Real y;
//   Boolean b;
//   Boolean b2;
// equation
//   when {b, b2} then
//     x = y;
//   end when;
// end When3;
// endResult
