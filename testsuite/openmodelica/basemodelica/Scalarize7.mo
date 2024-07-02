// name: Scalarize7
// status: correct
// cflags: -d=newInst -f --baseModelicaOptions=scalarize

function f
  input Real x[3];
  output Real y = x[1]+x[2]+x[3];
end f;

model Scalarize7
  Real x[3];
  Real y;
equation
  y = f(x);
end Scalarize7;

// Result:
// //! base 0.1.0
// package 'Scalarize7'
//   function 'f'
//     input Real[3] 'x';
//     output Real 'y' = 'x'[1] + 'x'[2] + 'x'[3];
//   end 'f';
//
//   model 'Scalarize7'
//     Real 'x[1]';
//     Real 'x[2]';
//     Real 'x[3]';
//     Real 'y';
//   equation
//     'y' = 'f'({'x[1]', 'x[2]', 'x[3]'});
//   end 'Scalarize7';
// end 'Scalarize7';
// endResult
