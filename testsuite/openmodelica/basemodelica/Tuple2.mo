// name: Tuple2
// status: correct

function f
  input Real x;
  output Real y = x;
  output Real z = x;
  output Real w = x;
end f;

model Tuple2
  Real x;
equation
  (x, , ) = f(time);
  (, x, ) = f(time);
  (, , x) = f(time);
  (,x, x) = f(time);
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Tuple2;

// Result:
// //! base 0.1.0
// package 'Tuple2'
//   function 'f'
//     input Real 'x';
//     output Real 'y' = 'x';
//     output Real 'z' = 'x';
//     output Real 'w' = 'x';
//   end 'f';
//
//   model 'Tuple2'
//     Real 'x';
//   equation
//     ('x', ) = 'f'(time);
//     (, 'x', ) = 'f'(time);
//     (, , 'x') = 'f'(time);
//     (, 'x', 'x') = 'f'(time);
//   end 'Tuple2';
// end 'Tuple2';
// endResult
