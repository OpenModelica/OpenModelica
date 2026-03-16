// name: If2
// status: correct

model If2
  Real x;
algorithm
  if time < 1 then
    x := sin(time);
  elseif time < 2 then
    x := cos(time);
  else
    x := 0;
  end if;
  annotation(__OpenModelica_commandLineOptions="-f");
end If2;

// Result:
// //! base 0.1.0
// package 'If2'
//   model 'If2'
//     Real 'x';
//   algorithm
//     if time < 1.0 then
//       'x' := sin(time);
//     elseif time < 2.0 then
//       'x' := cos(time);
//     else
//       'x' := 0.0;
//     end if;
//   end 'If2';
// end 'If2';
// endResult
