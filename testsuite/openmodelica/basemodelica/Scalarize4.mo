// name: Scalarize4
// status: correct
// cflags: -d=newInst -f --baseModelicaOptions=scalarize

record R
  Real x[3];
end R;

model Scalarize4
  R r[2] = fill(R({1.0, 2.0, 3.0}), 2);
equation
  r = array(R({4.0, 5.0, 6.0}) for i in 1:size(r, 1));
end Scalarize4;

// Result:
// //! base 0.1.0
// package 'Scalarize4'
//   record 'R'
//     Real[3] 'x';
//   end 'R';
//
//   model 'Scalarize4'
//     Real 'r[1].x[1]';
//     Real 'r[1].x[2]';
//     Real 'r[1].x[3]';
//     Real 'r[2].x[1]';
//     Real 'r[2].x[2]';
//     Real 'r[2].x[3]';
//   equation
//     'r[1].x[1]' = 1.0;
//     'r[1].x[2]' = 2.0;
//     'r[1].x[3]' = 3.0;
//     'r[2].x[1]' = 1.0;
//     'r[2].x[2]' = 2.0;
//     'r[2].x[3]' = 3.0;
//     'r[1].x[1]' = 4.0;
//     'r[1].x[2]' = 5.0;
//     'r[1].x[3]' = 6.0;
//     'r[2].x[1]' = 4.0;
//     'r[2].x[2]' = 5.0;
//     'r[2].x[3]' = 6.0;
//   end 'Scalarize4';
// end 'Scalarize4';
// endResult
