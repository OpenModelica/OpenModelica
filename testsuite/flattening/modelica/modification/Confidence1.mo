// name:     Confidence1
// keywords: modification confidence
// status:   correct
//

model Confidence1
  model M1
    Real x(start = 4.0);
    Real y(start = 5.0);
  equation
    x = y;
  end M1;

  M1 m1(x(start = 3.0));
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaFormat=showConfidence");
end Confidence1;

// Result:
// //! base 0.1.0
// package 'Confidence1'
//   model 'Confidence1'
//     Real 'm1.x'(start = 3.0 /* confidence = 1*/);
//     Real 'm1.y'(start = 5.0 /* confidence = 2*/);
//   equation
//     'm1.x' = 'm1.y';
//   end 'Confidence1';
// end 'Confidence1';
// endResult
