// name: If1
// status: correct

model If1
  Real x;
equation
  if time < 1 then
    x = sin(time);
  elseif time < 2 then
    x = cos(time);
  else
    x = 0;
  end if;
  annotation(__OpenModelica_commandLineOptions="-f");
end If1;

// Result:
// //! base 0.1.0
// package 'If1'
//   model 'If1'
//     Real 'x';
//   equation
//     if time < 1.0 then
//       'x' = sin(time);
//     elseif time < 2.0 then
//       'x' = cos(time);
//     else
//       'x' = 0.0;
//     end if;
//   end 'If1';
// end 'If1';
// endResult
