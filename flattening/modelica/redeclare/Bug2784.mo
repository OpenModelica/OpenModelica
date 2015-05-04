// name:     Bug2784.mo [BUG: #2784]
// keywords: redeclare modifier handling
// status:   correct
//
// check that modifiers on redeclare are not lost
//

class C1
  replaceable parameter Real r=3.14;
end C1;

model C2
  replaceable parameter C1 x1(redeclare replaceable Real r=3);
end C2;

// Result:
// class C2
//   parameter Real x1.r = 3.0;
// end C2;
// endResult
