// name:     if_then_elseif_else
// keywords: elseif
// status:   correct
//
//  Using elseif in if expressions
//
model ifThenElseIfElse
  Real out1,out2,out3,out4;
equation

  out1 = time;
  out2 = (if time < 1 then time else time^3);
  out3 = (if time < 1 then time else if time < 2 then time^2 else time^3);
  out4 = (if time < 1 then time elseif time < 2 then time^2 elseif time < 3 then time^3 elseif
             time < 4 then time^4 else time^5);

end ifThenElseIfElse;
// Result:
// class ifThenElseIfElse
//   Real out1;
//   Real out2;
//   Real out3;
//   Real out4;
// equation
//   out1 = time;
//   out2 = if time < 1.0 then time else time ^ 3.0;
//   out3 = if time < 1.0 then time else if time < 2.0 then time ^ 2.0 else time ^ 3.0;
//   out4 = if time < 1.0 then time else if time < 2.0 then time ^ 2.0 else if time < 3.0 then time ^ 3.0 else if time < 4.0 then time ^ 4.0 else time ^ 5.0;
// end ifThenElseIfElse;
// endResult
