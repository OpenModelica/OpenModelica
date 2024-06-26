// name: MoveBindings1
// status: correct
// cflags: -d=newInst -f --baseModelicaOptions=moveBindings

model M
  record R
    Real x;
    Real y;
  end R;

  Real x = 0;
  Real y[:] = {1, 2, 3};
  R r = R(1, 2);
  parameter Integer n = 0;
  Real z;
equation
  z = 1;
end M;

// Result:
// //! base 0.1.0
// package 'M'
//   record 'R'
//     Real 'x';
//     Real 'y';
//   end 'R';
//
//   model 'M'
//     Real 'x';
//     Real[3] 'y';
//     'R' 'r';
//     parameter Integer 'n' = 0;
//     Real 'z';
//   equation
//     'x' = 0.0;
//     'r' = 'R'(1.0, 2.0);
//     'y' = {1.0, 2.0, 3.0};
//     'z' = 1.0;
//   end 'M';
// end 'M';
// endResult
