// name: Scalarize2
// status: correct
// cflags: -d=newInst -f --baseModelicaOptions=scalarize

model M
  Real x[2];
end M;

function f
  input Real x[2, 2];
  output Real y[2, 2] = x*2;
end f;

model Scalarize2
  M m[2];
equation
  m.x = f(m.x);
end Scalarize2;

// Result:
// //! base 0.1.0
// package 'Scalarize2'
//   function 'f'
//     input Real[2, 2] 'x';
//     output Real[2, 2] 'y' = {{'x'[1,1] * 2.0, 'x'[1,2] * 2.0}, {'x'[2,1] * 2.0, 'x'[2,2] * 2.0}};
//   end 'f';
//
//   model 'Scalarize2'
//     Real 'm[1].x[1]';
//     Real 'm[1].x[2]';
//     Real 'm[2].x[1]';
//     Real 'm[2].x[2]';
//   equation
//     'm[1].x[1]' = ('f'({{'m[1].x[1]', 'm[1].x[2]'}, {'m[2].x[1]', 'm[2].x[2]'}}))[1,1];
//     'm[1].x[2]' = ('f'({{'m[1].x[1]', 'm[1].x[2]'}, {'m[2].x[1]', 'm[2].x[2]'}}))[1,2];
//     'm[2].x[1]' = ('f'({{'m[1].x[1]', 'm[1].x[2]'}, {'m[2].x[1]', 'm[2].x[2]'}}))[2,1];
//     'm[2].x[2]' = ('f'({{'m[1].x[1]', 'm[1].x[2]'}, {'m[2].x[1]', 'm[2].x[2]'}}))[2,2];
//   end 'Scalarize2';
// end 'Scalarize2';
// endResult
