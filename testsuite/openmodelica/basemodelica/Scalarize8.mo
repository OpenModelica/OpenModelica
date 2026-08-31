// name: Scalarize8
// status: correct

function f
  input Real x[3];
  output Real y = x[1]+x[2]+x[3];
end f;

model Scalarize8
  Real x[3];
  Real y = f(x);
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f --baseModelicaOptions=scalarize");
end Scalarize8;

// Result:
// //! base 0.1.0
// package 'Scalarize8'
//   function 'f'
//     input Real 'x'[3];
//     output Real 'y' = 'x'[1] + 'x'[2] + 'x'[3];
//   end 'f';
//
//   model 'Scalarize8'
//     Real 'x[1]';
//     Real 'x[2]';
//     Real 'x[3]';
//     Real 'y' = 'f'({'x[1]', 'x[2]', 'x[3]'});
//   end 'Scalarize8';
// end 'Scalarize8';
// endResult
