// name: Scalarize3
// status: correct

model M
  Real x[2] = f(x);
end M;

function f
  input Real x[2];
  output Real y[2] = x*2;
end f;

model Scalarize3
  M m[2];
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f --baseModelicaOptions=scalarize");
end Scalarize3;

// Result:
// //! base 0.1.0
// package 'Scalarize3'
//   function 'f'
//     input Real[2] 'x';
//     output Real[2] 'y' = {'x'[1] * 2.0, 'x'[2] * 2.0};
//   end 'f';
//
//   model 'Scalarize3'
//     Real 'm[1].x[1]';
//     Real 'm[1].x[2]';
//     Real 'm[2].x[1]';
//     Real 'm[2].x[2]';
//   equation
//     'm[1].x[1]' = ('f'('m[1].x'))[1];
//     'm[1].x[2]' = ('f'('m[1].x'))[2];
//     'm[2].x[1]' = ('f'('m[2].x'))[1];
//     'm[2].x[2]' = ('f'('m[2].x'))[2];
//   end 'Scalarize3';
// end 'Scalarize3';
// endResult
