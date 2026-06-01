// name:     Confidence2
// keywords: modification confidence
// status:   correct
//

model Confidence2
  model M2
    parameter Real xStart = 4.0;
    parameter Real yStart = 5.0;
    Real x(start = xStart);
    Real y(start = yStart);
  equation
    x = y;
  end M2;

  M2 m2(xStart = 3.0);
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaFormat=showConfidence");
end Confidence2;

// Result:
// //! base 0.1.0
// package 'Confidence2'
//   model 'Confidence2'
//     parameter Real 'm2.xStart' = 3.0 /* confidence = 1*/;
//     parameter Real 'm2.yStart' = 5.0 /* confidence = 2*/;
//     Real 'm2.x'(start = 'm2.xStart' /* confidence = 1*/);
//     Real 'm2.y'(start = 'm2.yStart' /* confidence = 2*/);
//   equation
//     'm2.x' = 'm2.y';
//   end 'Confidence2';
// end 'Confidence2';
// endResult
