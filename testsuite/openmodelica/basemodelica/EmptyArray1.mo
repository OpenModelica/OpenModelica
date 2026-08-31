// name: EmptyArray1
// status: correct

model EmptyArray1
  Real x[0];
  annotation(__OpenModelica_commandLineOptions="-f --newBackend");
end EmptyArray1;

// Result:
// //! base 0.1.0
// package 'EmptyArray1'
//   model 'EmptyArray1'
//   end 'EmptyArray1';
// end 'EmptyArray1';
// endResult
