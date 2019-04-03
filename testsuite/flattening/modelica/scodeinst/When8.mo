// name: When8
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When8
  Real x[3];
  Real y;
  Real z[3];
equation
  when time > 0 then
    x = {1, 2, 3};
    y = 2;
    z = {4, 5, 6};
  elsewhen time > 1 then
    x[1:2] = {3, 2};
    x[3] = 5;
    z = {9, 8, 7};
    y = 4;
  end when;
end When8;

// Result:
// class When8
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y;
//   Real z[1];
//   Real z[2];
//   Real z[3];
// equation
//   when time > 0.0 then
//     x[1] = 1.0;
//     x[2] = 2.0;
//     x[3] = 3.0;
//     y = 2.0;
//     z[1] = 4.0;
//     z[2] = 5.0;
//     z[3] = 6.0;
//   elsewhen time > 1.0 then
//     x[1] = 3.0;
//     x[2] = 2.0;
//     x[3] = 5.0;
//     z[1] = 9.0;
//     z[2] = 8.0;
//     z[3] = 7.0;
//     y = 4.0;
//   end when;
// end When8;
// endResult
