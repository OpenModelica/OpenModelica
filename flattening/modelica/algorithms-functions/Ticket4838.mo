// status: correct

model Sum
function s
  input Integer a;
  input Integer i;
  output Integer b;
  algorithm
  if i == 0 then
    b := a;
  else
    b := s(a+1,i-1);
  end if;
end s;
  constant Integer x = s(0,4);
end Sum;

// Result:
// function Sum.s
//   input Integer a;
//   input Integer i;
//   output Integer b;
// algorithm
//   if i == 0 then
//     b := a;
//   else
//     return Sum.s(1 + a, -1 + i);
//   end if;
// end Sum.s;
//
// class Sum
//   constant Integer x = 4;
// end Sum;
// endResult
