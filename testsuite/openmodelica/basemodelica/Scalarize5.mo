// name: Scalarize5
// status: correct
// cflags: -d=newInst -f --baseModelicaOptions=scalarize

model A
  Real x[3](each start = 1.0);
  Real y;
end A;

model Scalarize5
  A a1[2](y = {1, 2});
  A a2;
  Real x[2];
equation
  x = a1.x * a2.x;
end Scalarize5;

// Result:
// //! base 0.1.0
// package 'Scalarize5'
//   model 'Scalarize5'
//     Real 'a1[1].x[1]'(start = 1.0);
//     Real 'a1[1].x[2]'(start = 1.0);
//     Real 'a1[1].x[3]'(start = 1.0);
//     Real 'a1[1].y' = 1.0;
//     Real 'a1[2].x[1]'(start = 1.0);
//     Real 'a1[2].x[2]'(start = 1.0);
//     Real 'a1[2].x[3]'(start = 1.0);
//     Real 'a1[2].y' = 2.0;
//     Real 'a2.x[1]'(start = 1.0);
//     Real 'a2.x[2]'(start = 1.0);
//     Real 'a2.x[3]'(start = 1.0);
//     Real 'a2.y';
//     Real 'x[1]';
//     Real 'x[2]';
//   equation
//     'x[1]' = 'a1[1].x[1]' * 'a2.x[1]' + 'a1[1].x[2]' * 'a2.x[2]' + 'a1[1].x[3]' * 'a2.x[3]';
//     'x[2]' = 'a1[2].x[1]' * 'a2.x[1]' + 'a1[2].x[2]' * 'a2.x[2]' + 'a1[2].x[3]' * 'a2.x[3]';
//   end 'Scalarize5';
// end 'Scalarize5';
// endResult
