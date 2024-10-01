// name: Scalarize1
// status: correct

model M
  Real x[2];
equation
  x = {1, time};
end M;

model Scalarize1
  M m[2];
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f --baseModelicaOptions=scalarize");
end Scalarize1;

// Result:
// //! base 0.1.0
// package 'Scalarize1'
//   model 'Scalarize1'
//     Real 'm[1].x[1]';
//     Real 'm[1].x[2]';
//     Real 'm[2].x[1]';
//     Real 'm[2].x[2]';
//   equation
//     'm[1].x[1]' = 1.0;
//     'm[1].x[2]' = time;
//     'm[2].x[1]' = 1.0;
//     'm[2].x[2]' = time;
//   end 'Scalarize1';
// end 'Scalarize1';
// endResult
