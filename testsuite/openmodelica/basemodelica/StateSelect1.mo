// name: StateSelect1
// status: correct

model StateSelect1
  Real x(stateSelect = StateSelect.never);
  parameter StateSelect s = StateSelect.always;
  Real y(stateSelect = s);
  annotation(__OpenModelica_commandLineOptions="-f");
end StateSelect1;

// Result:
// //! base 0.1.0
// package 'StateSelect1'
//   model 'StateSelect1'
//     Real 'x'(stateSelect = StateSelect.never);
//     parameter StateSelect 's' = StateSelect.always;
//     Real 'y'(stateSelect = StateSelect.always);
//   end 'StateSelect1';
// end 'StateSelect1';
// endResult
