// name:     ConditionalArrayExpression2
// keywords: equation,array
// status:   correct
//
// The sizes must fit in array expressions and equations.

model ConditionalArrayExpression2
  Real a=time*4, b=2.0, c[2], d, e;
equation
  {d, e} = if a > b then c else {e, d*2+1};
  if time < 0.5 then
     c = {1,0};
  else
     c[1] = 2;
     c[2] = 4;
  end if;
end ConditionalArrayExpression2;

// Result:
// class ConditionalArrayExpression2
//   Real a = 4.0 * time;
//   Real b = 2.0;
//   Real c[1];
//   Real c[2];
//   Real d;
//   Real e;
// equation
//   d = if a > b then c[1] else e;
//   e = if a > b then c[2] else 1.0 + 2.0 * d;
//   if time < 0.5 then
//   c[1] = 1.0;
//   c[2] = 0.0;
//   else
//   c[1] = 2.0;
//   c[2] = 4.0;
//   end if;
// end ConditionalArrayExpression2;
// endResult
