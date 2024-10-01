// name: Scalarize6
// status: correct

function f
  input Real x[3];
  output Real y[3] = x*2;
end f;

model A
  parameter Real x[3] = f(x);
end A;

model Scalarize6
  A a;
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f --baseModelicaOptions=scalarize");
end Scalarize6;

// Result:
// //! base 0.1.0
// package 'Scalarize6'
//   function 'f'
//     input Real[3] 'x';
//     output Real[3] 'y' = {'x'[1] * 2.0, 'x'[2] * 2.0, 'x'[3] * 2.0};
//   end 'f';
//
//   model 'Scalarize6'
//     parameter Real 'a.x[1]' = ('f'('a.x'))[1];
//     parameter Real 'a.x[2]' = ('f'('a.x'))[2];
//     parameter Real 'a.x[3]' = ('f'('a.x'))[3];
//   end 'Scalarize6';
// end 'Scalarize6';
// endResult
