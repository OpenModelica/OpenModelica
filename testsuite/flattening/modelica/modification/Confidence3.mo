// name:     Confidence3
// keywords: modification confidence
// status:   correct
//

model Confidence3
  model M3
    model MLocal
      parameter Real xStart = 4.0;
      Real x(start = xStart);
    end MLocal;
    model MLocalWrapped
      parameter Real xStart = 4.0;
      MLocal m(xStart = xStart);
    end MLocalWrapped;
    MLocal mx;
    MLocalWrapped my(xStart = 3.0);
  equation
    mx.x = my.m.x;
  end M3;

  M3 m3;
  annotation(__OpenModelica_commandLineOptions="-f --baseModelicaFormat=showConfidence");
end Confidence3;

// Result:
// //! base 0.1.0
// package 'Confidence3'
//   model 'Confidence3'
//     parameter Real 'm3.mx.xStart' = 4.0 /* confidence = 3*/;
//     Real 'm3.mx.x'(start = 'm3.mx.xStart' /* confidence = 3*/);
//     parameter Real 'm3.my.xStart' = 3.0 /* confidence = 2*/;
//     parameter Real 'm3.my.m.xStart' = 'm3.my.xStart' /* confidence = 2*/;
//     Real 'm3.my.m.x'(start = 'm3.my.m.xStart' /* confidence = 2*/);
//   equation
//     'm3.mx.x' = 'm3.my.m.x';
//   end 'Confidence3';
// end 'Confidence3';
// endResult
