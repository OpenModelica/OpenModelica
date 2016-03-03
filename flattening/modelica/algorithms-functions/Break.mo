// name:     Break
// keywords: algorithm break
// status:   correct
//           [While statements in algorithms not supported yet]
//
// break statement in algorithms

model Break
  Real x, y, z, a;
equation
  y = sin(time);
protected
  Integer i;
algorithm
  i := 0;
  a := y-1.0;
  while ((i/10) < y) loop
    a := a + 0.5;
    if a>y then break; end if;
    i := i + 1;
  end while;
algorithm
  for i in 1:3 loop
    if i > 2 then
      x := x - i;
    end if;
    if i < 1 then
      x := 1.0;
    elseif i < 2 then
      x := 2.0;
    else
      x := 3.0;
      break;
    end if;
  end for;
algorithm
  when y>0.9 then
    z := 0.0;
  end when;
end Break;

// Result:
// class Break
//   Real x;
//   Real y;
//   Real z;
//   Real a;
//   protected Integer i;
// equation
//   y = sin(time);
// algorithm
//   i := 0;
//   a := -1.0 + y;
//   while 0.1 * /*Real*/(i) < y loop
//     a := 0.5 + a;
//     if a > y then
//       break;
//     end if;
//     i := 1 + i;
//   end while;
// algorithm
//   for i in 1:3 loop
//     if i > 2 then
//       x := x - /*Real*/(i);
//     end if;
//     if i < 1 then
//       x := 1.0;
//     elseif i < 2 then
//       x := 2.0;
//     else
//       x := 3.0;
//       break;
//     end if;
//   end for;
// algorithm
//   when y > 0.9 then
//     z := 0.0;
//   end when;
// end Break;
// endResult
