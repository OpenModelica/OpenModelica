// name: Break1
// status: correct

function f
  input Real x[:];
  output Real y = 0;
algorithm
  for v in x loop
    if v > 1 then
      y := v;
      break;
    end if;
  end for;
end f;

model Break1
  Real x[3] = {1, 2, 3};
  Real y = f(x);
  annotation(__OpenModelica_commandLineOptions="-f");
end Break1;

// Result:
// //! base 0.1.0
// package 'Break1'
//   function 'f'
//     input Real 'x'[:];
//     output Real 'y' = 0.0;
//   algorithm
//     for 'v' in 'x' loop
//       if 'v' > 1.0 then
//         'y' := 'v';
//         break;
//       end if;
//     end for;
//   end 'f';
//
//   model 'Break1'
//     Real 'x'[3];
//     Real 'y' = 'f'('x');
//   equation
//     'x' = {1.0, 2.0, 3.0};
//   end 'Break1';
// end 'Break1';
// endResult
